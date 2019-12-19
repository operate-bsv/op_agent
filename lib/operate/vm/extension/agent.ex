defmodule Operate.VM.Extension.Agent do
  @moduledoc """
  Extends the VM state with functions for accessing the running agent.
  """
  use Operate.VM.Extension
  alias Operate.{Util, VM}
  

  def extend(vm) do
    vm
    |> VM.set!("agent", [])
    |> VM.set_function!("agent.exec", fn _vm, args -> apply(__MODULE__, :exec, args) end)
    |> VM.set_function!("agent.load_tape", fn _vm, args -> apply(__MODULE__, :load_tape, args) end)
    |> VM.set_function!("agent.load_tapes_by", fn _vm, args -> apply(__MODULE__, :load_tapes_by, args) end)
    |> VM.set_function!("agent.run_tape", fn _vm, args -> apply(__MODULE__, :run_tape, args) end)
  end


  @doc """
  Loads and runs a tape from the given txid
  """
  @deprecated "Use load_tape/2 and run_tape/2 instead"
  def exec(txid, state \\ nil) do
    with {:ok, tape} <- Operate.load_tape(txid),
         {:ok, tape} <- Operate.run_tape(tape, state: state)
    do
      tape.result
    else
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  Loads a tape by the given txid and returns the tape
  """
  def load_tape(txid, opts \\ %{}) do
    opts = VM.decode(opts) |> VM.parse_opts
    Operate.load_tape!(txid, opts)
  end


  @doc """
  Loads a list of tapes by the given query and returns the list
  """
  def load_tapes_by(query, opts \\ %{}) do
    opts = VM.decode(opts) |> VM.parse_opts
    VM.decode(query)
    |> Operate.load_tapes_by!(opts)
  end

  
  @doc """
  Runs the given tape, and returns the result
  """
  def run_tape(tape, opts \\ %{}) do
    opts = VM.decode(opts) |> VM.parse_opts
    VM.decode(tape)
    |> Util.restruct
    |> Operate.run_tape!(opts)
    |> Map.get(:result)
  end

end
