defmodule SBEFeed do
  use GenEvent
  @behavior Change
  @buffer_size 100

  def start_link(options \\ []) do
    GenEvent.start_link(options)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_event({state, sku}, states) when map_size(states) >= @buffer_size do
    send_events(Map.put(states, sku, normalize(state)))
    {:ok, %{}}
  end
  def handle_event({state, sku}, states) do
    {:ok, Map.put(states, sku, normalize(state))}
  end
  def handle_event(:flush, states) do
    send_events(states)
    {:ok, %{}}
  end

  defp normalize(:outofstock) do
    []
  end
  defp normalize(:instock, lid) do
    [lid]
  end
  defp normalize(:change, lid_list) do
    lid_list
  end

  defp send_events(states) do
    for state <- states do
      Poison.encode!(state) |> IO.puts
    end
  end

end
