defmodule FBAgent.Function do
  @moduledoc """
  Function module. Defines a Function struct so adapters can wrap returned
  functions in a consistent structure.
  """
  defstruct [:ref, :hash, :name, :script]

  @typedoc "Function"
  @type t :: %__MODULE__{
    ref: String.t,
    hash: String.t,
    name: String.t,
    script: String.t
  }
end