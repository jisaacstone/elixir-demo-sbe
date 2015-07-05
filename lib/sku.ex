defmodule Sku do
  use GenServer
  
  ## CLIENT API ##

  def start_link(location_id, opts \\ []) do
    GenServer.start_link(__MODULE__, [location_id], opts)
  end

  @doc """
  Mark sku availabile at a location
  """
  @spec in_stock_at(GerServer.server, String.t) :: Change.t
  def in_stock_at(server, location_id) do
    GenServer.call(server, {:add, location_id})
  end

  @doc """
  Mark sku unavailabile at a location
  """
  @spec out_of_stock_at(GerServer.server, String.t) :: Change.t
  def out_of_stock_at(server, location_id) do
    GenServer.call(server, {:remove, location_id})
  end

  @doc """
  Get current available locations
  """
  def get_locations(server) do
    GenServer.call(server, :get_locations)
  end

  ## SERVER API ##

  def init(location_ids) do
    {:ok, initial_state(location_ids)}
  end

  def handle_call(:get_locations, _from, locations) do
    {:reply, locations, locations}
  end
  def handle_call(action, _from, locations) do
    {change, newlocations} = determine_change(action, locations)
    {:reply, {change, newlocations}, newlocations}
  end

  defp initial_state(location_ids) do
    # Except not because it is a stub
    location_ids
  end

  defp determine_change({:remove, _lid}, []) do
    {:nochange, []}
  end
  defp determine_change({:remove, lid}, [lid]) do
    {:outofstock, []}
  end
  defp determine_change({:remove, lid}, [lid | tail]) do
    {:change, tail}
  end
  defp determine_change({:remove, lid}, [head | tail]) do
    case determine_change({:remove, lid}, tail) do
      {:outofstock, newtail} ->
        {:change, [head | newtail]}
      {change_or_nochange, newtail} ->
        {change_or_nochange, [head | newtail]}
    end
  end

  defp determine_change({:add, lid}, []) do
    {:instock, [lid]}
  end
  defp determine_change({:add, lid}, locations) do
    if Enum.member?(locations, lid) do
      {:nochange, locations}
    else
      {:change, [lid | locations]}
    end
  end
end
