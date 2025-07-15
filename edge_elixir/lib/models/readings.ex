defmodule Models.Readings do
  defstruct lpg: 0.0, ch4: 0.0, co: 0.0, temperature: 0.0
  @type t :: %__MODULE__{lpg: float(), ch4: float(), co: float(), temperature: float()}
end
