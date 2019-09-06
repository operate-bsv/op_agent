defmodule FBAgent.Tape do
  @moduledoc """
  A Functional Bitcoin Tape module. A tape is is made up of one or more cells,
  where each cell contains a single atomic procedure call.

  When a tape is run, each cell is inexecuted in turn, with the result from
  each cell passed as the first argument to the next cell's procedure. The
  tapes's result is calculated cell by cell - function by function.

  ## Examples

      iex> {:ok, tape} = %FBAgent.Tape{cells: [
      ...>   %FBAgent.Cell{script: "return function(ctx, a) return (ctx or 0) + a end", params: [2]},
      ...>   %FBAgent.Cell{script: "return function(ctx, a) return (ctx or 0) + a end", params: [3]},
      ...>   %FBAgent.Cell{script: "return function(ctx, a) return (ctx or 0) + a end", params: [4]}
      ...> ]}
      ...> |> FBAgent.Tape.run(FBAgent.VM.init)
      ...> tape.result
      9
  """
  alias FBAgent.VM
  alias FBAgent.Cell

  @typedoc "Execution Tape"
  @type t :: %__MODULE__{
    tx: map,
    cells: [Cell.t, ...],
    result: VM.lua_output,
    error: binary
  }

  defstruct tx: nil, cells: [], result: nil, error: nil


  @doc """
  Runs the given tape in the given VM state.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context passed to the first cell procedure.
  Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell
  has an error the entire tape fails. Disable strict mode by setting to `false`.

  ## Examples

      iex> {:ok, tape} = %FBAgent.Tape{cells: [
      ...>   %FBAgent.Cell{script: "return function(ctx, a) return (ctx or '') .. a end", params: ["b"]},
      ...>   %FBAgent.Cell{script: "return function(ctx, a) return (ctx or '') .. a end", params: ["c"]},
      ...>   %FBAgent.Cell{script: "return function(ctx) return string.reverse(ctx) end", params: []}
      ...> ]}
      ...> |> FBAgent.Tape.run(FBAgent.VM.init, context: "a")
      ...> tape.result
      "cba"
  """
  @spec run(t, VM.vm, keyword) :: {:ok, t} | {:error, t}
  def run(tape, vm, options \\ []) do
    vm = Sandbox.set!(vm, "tx", %{txid: get_in(tape.tx, ["tx", "h"])})
    context = Keyword.get(options, :context, nil)
    strict = Keyword.get(options, :strict, true)
    case Enum.reduce_while(tape.cells, context, fn(cell, ctx) ->
      case Cell.exec(cell, vm, context: ctx) do
        {:ok, result}   -> {:cont, result}
        {:error, error} ->
          if strict, do: {:halt, {:error, error}}, else: {:cont, ctx}
      end
    end) do
      {:error, error} -> {:error, Map.put(tape, :error, error)}
      result          -> {:ok, Map.put(tape, :result, result)}
    end
  end


  @doc """
  As `f:FBAgent.Tape.run/3`, but returns the tape or raises an exception.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context passed to the first cell procedure.
  Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell
  has an error the entire tape fails. Disable strict mode by setting to `false`.
  """
  @spec run!(t, VM.vm, keyword) :: t
  def run!(tape, vm, options \\ []) do
    case run(tape, vm, options) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  Todoc
  """
  def valid?(tape) do
    tape.cells
    |> Enum.all?(&(Cell.valid?(&1)))
  end


  @doc """
  Returns a list of procedure references from the given tape's cells.
  """
  def procedure_refs(tape) do
    tape.cells
    |> Enum.map(&(&1.ref))
  end
  
end