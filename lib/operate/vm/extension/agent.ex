defmodule Operate.VM.Extension.Agent do
  @moduledoc """
  Extends the VM state with functions for accessing the running agent.
  """
  use Operate.VM.Extension
  alias Operate.VM
  

  def extend(vm) do
    vm
    |> VM.set!("agent", [])
    |> VM.set_function!("agent.exec", fn _vm, args -> apply(__MODULE__, :exec, args) end)
  end


  @doc """
  Loads and runs a tape from the given txid
  """
  def exec(txid, state \\ nil) do
    with {:ok, tape} <- Operate.load_tape(txid),
         {:ok, tape} <- Operate.run_tape(tape, state: state)
    do
      tape.result
    else
      {:error, tape} -> raise tape.error
    end
  end
end
