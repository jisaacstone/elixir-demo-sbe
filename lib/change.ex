defmodule Change do
  use Behavior

  @type t :: :nochange | :outofstock | {:change [String.t]} | {:instock, String.t}
  @type update :: {t, String.t}

  defcallback handle_event(update, term) :: term
end
