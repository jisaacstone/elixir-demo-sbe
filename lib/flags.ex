defmodule Flags do
  use GenEvent
  @behaviour Change

  def handle_event({{:outofstock, []}, sku}, _) do
    {setflag(sku, false), :_}
  end
  def handle_event({{:instock, _locations}, sku}, _) do
    {setflag(sku, true), :_}
  end
  def handle_event(_, _) do
    {:ok, :_}
  end

  defp setflag(sku, status) do
    IO.puts("sku #{sku} set to #{status}")
  end
end
