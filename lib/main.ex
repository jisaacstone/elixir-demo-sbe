defmodule Main do
  use GenServer
  import Supervisor.Spec

  @table :skus

  ## CLIENT ##

  def start_link(listeners, opts \\ []) do
    GenServer.start_link(__MODULE__, listeners, opts)
  end

  @spec qty_at_location(GerServer.server, String.t, non_neg_integer, String.t) :: term
  def qty_at_location(server, sku, qty, location) do
    GenServer.call(server, {:qty_at_location, sku, qty, location})
  end

  ## SERVER ##

  def init(listeners) do
    {:ok, sup_pid} = Supervisor.start_link(
      [ worker(Sku, [], restart: :transient) ],
      strategy: :simple_one_for_one )
    {:ok, %{skus: :ets.new(@table, [ :named_table, read_concurrency: true ]),
            sku_super: sup_pid,
            listeners: listeners}}
  end

  def handle_cast({:qty_at_location, sku, qty, location}, state) do
    change = case :ets.lookup(@table, sku) do
      [{^sku, pid}] ->
        Sku.update(pid, location, qty)
      [] ->
        {:ok, pid} = Supervisor.start_child(state.sku_super)
        :ets.insert(state.skus, {sku, pid})
        {:instock, Sku.get_locations(pid)}
    end
    notify(change, state.listeners)
    state
  end

  def handle_cast({:delete, sku}, state) do
    case :ets.lookup(@table, sku) do
      [{^sku, pid}] ->
        Supervisor.terminate_child(state.sku_super, pid)
        :ets.delete(@table, sku)
        notify(:outofstock, state.listeners)
        {:noreply, state}
      [] ->
        {:noreply, state}
    end
  end

  @spec notify(Change.t, [GenServer.server]) :: term
  defp notify(:nochange, _listeners) do
    :nil
  end
  defp notify(change, listeners) do
    for listener <- listeners do
      GenEvent.notify(listeners, change)
    end
  end
end
