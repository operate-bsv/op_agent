defmodule FBAgent.VM.AgentExtension do
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
    |> Sandbox.set!("agent", [])
    |> Sandbox.let_elixir_eval!("agent.exec", fn _state, args -> apply(__MODULE__, :exec, args) end)
  end

  @doc """
  Loads and runs a tape from the given txid
  """
  def exec(txid, ctx \\ nil) do
    with {:ok, tape} <- FBAgent.load_tape(txid),
         {:ok, tape} <- FBAgent.run_tape(tape, context: ctx)
    do
      tape.result
    else
      {:error, tape} -> raise tape.error
    end
  end
end
