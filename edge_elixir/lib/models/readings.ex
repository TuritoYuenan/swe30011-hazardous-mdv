defmodule Models.Readings do
  @moduledoc """
  Represents the readings from a sensor.
  This module defines a struct for sensor readings, including properties for LPG, CH4, CO, and temperature.
  """
  defstruct lpg: 0.0, ch4: 0.0, co: 0.0, temperature: 0.0
  @type t :: %__MODULE__{lpg: float(), ch4: float(), co: float(), temperature: float()}
end
