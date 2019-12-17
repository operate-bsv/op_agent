defmodule Operate.VM.Extension.Base do
  @moduledoc """
  Extends the VM state with functions for encoding and decoding hex and base64
  strings.
  """
  use Operate.VM.Extension
  alias Operate.VM
  

  def extend(vm) do
    vm
    |> VM.set!("base", [])
    |> VM.set_function!("base.encode16", fn _vm, args -> apply(__MODULE__, :encode16, args) end)
    |> VM.set_function!("base.decode16", fn _vm, args -> apply(__MODULE__, :decode16, args) end)
    |> VM.set_function!("base.encode64", fn _vm, args -> apply(__MODULE__, :encode64, args) end)
    |> VM.set_function!("base.decode64", fn _vm, args -> apply(__MODULE__, :decode64, args) end)
  end


  @doc """
  Encodes the given binary string into a hex string.
  """
  def encode16(val), do: Base.encode16(val, case: :lower)


  @doc """
  Decodes the given hex string into a binary string.
  """
  def decode16(val), do: Base.decode16!(val, case: :mixed)


  @doc """
  Encodes the given binary string into a hex string.
  """
  def encode64(val), do: Base.encode64(val)


  @doc """
  Decodes the given hex string into a binary string.
  """
  def decode64(val), do: Base.decode64!(val)
  
end