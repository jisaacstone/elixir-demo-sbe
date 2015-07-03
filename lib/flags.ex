defmodule Flags do
  use GenEvent
  @behavior Change

  def start_link(options \\ []) do
    GenEvent.start_link(options)
  end

  def handle_event({:outofstock, sku}, _) do
    setflag(sku, false)
  end
  def handle_event({{:instock, _}, sku}, _) do
    setflag(sku, true)
  end
  def handle_event(_, _) do
    # ignore
  end

  defp setflag(sku, status) do
    IO.puts("sku #{sku} set to #{status}")
  end
end
