defmodule Main do
  use GenServer
  import Supervisor.Spec
  @table :skus

  ## CLIENT ##

  def start_link({event_handler, listeners}, opts \\ []) do
    for listener <- listeners do
      IO.inspect(listener)
      GenEvent.add_handler(event_handler, listener, [])
    end
    GenServer.start_link(__MODULE__, event_handler, opts)
  end

  @spec qty_at_location(GerServer.server, String.t, non_neg_integer, String.t) :: term
  def qty_at_location(server, sku, qty, location) do
    GenServer.cast(server, {:qty_at_location, sku, qty, location})
  end

  ## SERVER ##

  def init(event_handler) do
    {:ok, sup_pid} = Supervisor.start_link(
      [ worker(Sku, [], restart: :transient) ],
      strategy: :simple_one_for_one )
    {:ok, %{skus: :ets.new(@table, [ :named_table, read_concurrency: true ]),
            sku_super: sup_pid,
            event_handler: event_handler}}
  end

  def handle_cast({:qty_at_location, sku, 0, location}, state) do
    case :ets.lookup(@table, sku) do
      [{^sku, pid}] ->
        GenEvent.notify(
          state.event_handler,
          {Sku.out_of_stock_at(pid, location), sku})
        {:noreply, state}
      [] ->
        {:noreply, state}
    end
  end
  def handle_cast({:qty_at_location, sku, qty, location}, state) when qty > 0 do
    change = case :ets.lookup(@table, sku) do
      [{^sku, pid}] ->
        Sku.in_stock_at(pid, location)
      [] ->
        {:ok, pid} = Supervisor.start_child(state.sku_super, [location])
        :ets.insert(state.skus, {sku, pid})
        {:instock, Sku.get_locations(pid)}
    end
    GenEvent.notify(state.event_handler, {change, sku})
    {:noreply, state}
  end

  def handle_cast({:delete, sku}, state) do
    case :ets.lookup(@table, sku) do
      [{^sku, pid}] ->
        Supervisor.terminate_child(state.sku_super, pid)
        :ets.delete(@table, sku)
        GenEvent.notify(state.event_handler, {:outofstock, sku})
        {:noreply, state}
      [] ->
        {:noreply, state}
    end
  end
end
