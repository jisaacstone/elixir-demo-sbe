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

  @sbefeed_name Listener.SBEFeed
  @flags_name Listener.Flags

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    listeners = [
      worker(SBEFeed, [[name: @sbefeed_name]]),
      worker(Flags, [[name: @flags_name]])]
    main = worker(Main, [@sbefeed_name, @flags_name, [name: Main] ])

    supervise(listeners ++ [main], strategy: :one_for_one)
  end
end
