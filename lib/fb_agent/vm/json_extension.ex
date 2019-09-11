defmodule FBAgent.VM.JsonExtension do
  @moduledoc """
  Extends the VM state with functions for encoding and decoding JSON.
  """
  alias FBAgent.VM


  @doc """
  Sets up the given VM state setting a table with attached function handlers.
  """
  @spec setup(VM.vm) :: VM.vm
  def setup(state) do
    state
    |> Sandbox.set!("json", [])
    |> Sandbox.let_elixir_eval!("json.decode", fn _state, args -> apply(__MODULE__, :decode, args) end)
    |> Sandbox.let_elixir_eval!("json.encode", fn _state, args -> apply(__MODULE__, :encode, args) end)
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