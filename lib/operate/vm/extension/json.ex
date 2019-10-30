defmodule Operate.VM.Extension.JSON do
  @moduledoc """
  Extends the VM state with functions for encoding and decoding JSON.
  """
  use Operate.VM.Extension
  alias Operate.VM
  

  def extend(vm) do
    vm
    |> VM.set!("json", [])
    |> VM.set_function!("json.decode", fn _vm, args -> apply(__MODULE__, :decode, args) end)
    |> VM.set_function!("json.encode", fn _vm, args -> apply(__MODULE__, :encode, args) end)
  end


  @doc """
  Decodes the given JSON string.
  """
  def decode(val), do: Jason.decode!(val)

  @doc """
  Encodes the given value into a JSON string,
  """
  def encode(val), do: VM.decode(val) |> Jason.encode!
  
end