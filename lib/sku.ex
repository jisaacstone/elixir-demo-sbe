defmodule Sku do
  use GenServer
  
  ## CLIENT API ##

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Returns one of
   :nochange
   :outofstock
   {:change, [location_ids]}
   {:instock, location_id}
  """
  def update_qty(server, location_id, qty) do
    GenServer.call(server, {:update, location_id, qty})
  end

  ## SERVER API ##

  def init() do
    {:ok, initial_state}
  end

  def handle_call({:update, lid, qty}, _from, locations) do
    {action, newlocations} = update(lid, qty, locations)
    {:reply, action, newlocations}
  end

  defp initial_state do
    # Stub
    %{"a_location_id" => 5}
  end

  @doc """
  Determing the change (if any) to the sku's availability state

  Returns a tuple of `{change, state}`
  `change` can be either the atom `:nochange` or a tuple
  `{change_type, location_ids}`
  """
  defp update(lid, qty, locations = %{lid => qty}) do
    {:nochange, locations}
  end
  defp update(lid, 0, locations = %{lid => _qty}) when map_size(locations) == 1 do
    {:outofstock, %{}}
  end
  defp update(lid, 0, locations = %{lid => qty}) do
    newlocations = Map.delete(locations, lid)
    {{:change, Map.keys(newlocations)}, newlocations}
  end
  defp update(lid, 0, locations) when map_size(locations) == 0 do
    {:nochange, locations}
  end
  defp update(lid, qty, locations) when map_size(locations) == 0 do
    {{:instock, lid}, Map.put(locations, lid, qty)} 
  end
  defp update(lid, qty, locations) do
    newlocations = Map.put(locations, lid, qty)
    {{:change, Map.keys(newlocations)}, newlocations} 
  end
end
