defmodule Change do
  use Behaviour

  @type t :: {:nochange | :outofstock | :change | :instock, [String.t]}
  @type update :: {t, String.t}

  defcallback handle_event(update, term) :: term
end
