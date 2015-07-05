defmodule Demo do
  use Application

  @doc """
  Just start the supervisor. Nothing fancy.
  """
  def start(_type, _args) do
    Demo.Supervisor.start_link
  end

end

defmodule Demo.Supervisor do
  use Supervisor

  @sbefeed_name SBEFeed
  @flags_name Flags
  @event_name Sku.EventManager

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    workers = [
      worker(GenEvent, [[name: @event_name]]),
      #worker(SBEFeed, [[name: @sbefeed_name]]),
      #worker(Flags, [[name: @flags_name]]),
      worker(Main, [{@event_name, [@sbefeed_name, @flags_name]}, [name: Main]])]
    supervise(workers, strategy: :one_for_one)
  end
end
