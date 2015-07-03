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
    case :ets.lookup(@table, sku) do
      [{^sku, pid}] ->
        notify(Sku.update(pid, location, qty), state.listeners)
        {:noreply, state}
      [] ->
        {:noreply, init_sku(sku, state)}
    end
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

  def get_state(sku) do
    %{"#{sku}_location_1" => 5}
  end

  defp init_sku(sku, state) do
    {:ok, pid} = Supervisor.start_child(
      state.sku_super,
      start_fun: {Sku, get_state, [sku]})
    refs = HashDict.put(state.refs, Process.monitor(pid), sku)
    :ets.insert(state.skus, {sku, pid})
    %{state | refs: refs}
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
