defmodule Flags do
  use GenEvent

  def handle_event({:outofstock, sku}, _) do
    setflag(sku, false)
  end
  def handle_event({{:instock, _}, sku}, _) do
    setFlag(sku, true)
  end
  def handle_event(_, _) do
    # ignore
  end

  defp setflag(sku, status) do
    IO.puts("sku #{sku} set to #{status}")
  end
end
