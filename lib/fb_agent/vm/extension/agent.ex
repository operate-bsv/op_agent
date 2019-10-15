defmodule FBAgent.VM.Extension.Agent do
  @moduledoc """
  Extends the VM state with functions for encoding and decoding JSON.
  """
  alias FBAgent.VM

  @behaviour VM.Extension

  def extend(vm) do
    vm
    |> VM.set!("agent", [])
    |> VM.set_function!("agent.exec", fn _vm, args -> apply(__MODULE__, :exec, args) end)
  end

  @doc """
  Loads and runs a tape from the given txid
  """
  def exec(txid, state \\ nil) do
    with {:ok, tape} <- FBAgent.load_tape(txid),
         {:ok, tape} <- FBAgent.run_tape(tape, state: state)
    do
      tape.result
    else
      {:error, tape} -> raise tape.error
    end
  end
end
