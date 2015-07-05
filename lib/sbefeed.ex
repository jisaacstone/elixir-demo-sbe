defmodule SBEFeed do
  use GenEvent
  @behaviour Change
  @buffer_size 5

  def init(_args) do
    IO.puts("SBEFeed starting")
    {:ok, %{}}
  end

  def handle_event({{_event, locations}, sku}, states) when map_size(states) >= @buffer_size do
    send_events(Map.put(states, sku, locations))
    {:ok, %{}}
  end
  def handle_event({{_event, locations}, sku}, states) do
    {:ok, Map.put(states, sku, locations)}
  end
  def handle_event(:flush, states) do
    send_events(states)
    {:ok, %{}}
  end

  defp send_events(states) do
    for state <- states do
      IO.inspect state
    end
  end

end
