defmodule Operate.Op do
  @moduledoc """
  Defines an Op struct. Adapters implementing `c:Operate.Adapter.fetch_ops/2`
  should map the response in to this consistent structure.
  """
  defstruct [:ref, :hash, :name, :script]

  @typedoc "Operate Op"
  @type t :: %__MODULE__{
    ref: String.t,
    hash: String.t,
    name: String.t,
    script: String.t
  }
end