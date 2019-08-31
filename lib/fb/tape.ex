defmodule FB.Tape do
  @moduledoc """
  A Functional Bitcoin Tape module. A tape is is made up of one or more cells,
  where each cell contains a single atomic procedure call.

  When a tape is run, each cell is inexecuted in turn, with the result from
  each cell passed as the first argument to the next cell's procedure. The
  tapes's result is calculated cell by cell - function by function.

  ## Examples

      iex> {:ok, tape} = %FB.Tape{cells: [
      ...>   %FB.Cell{ref: "a", script: "m = {}; m.main = function(ctx, a) return (ctx or 0) + a end; return m", params: [2]},
      ...>   %FB.Cell{ref: "b", script: "m = {}; m.main = function(ctx, a) return (ctx or 0) + a end; return m", params: [3]},
      ...>   %FB.Cell{ref: "c", script: "m = {}; m.main = function(ctx, a) return (ctx or 0) + a end; return m", params: [4]}
      ...> ]}
      ...> |> FB.Tape.load!
      ...> |> FB.Tape.run
      ...> tape.result
      9
  """
  alias FB.VM

  @typedoc "Execution Tape"
  @type t :: %__MODULE__{
    tx: map,
    tx: VM.vm,
    cells: list,
    result: VM.lua_output,
    error: String.t
  }

  defstruct tx: nil, vm: nil, cells: [], result: nil, error: nil


  @doc """
  Executes a function at the given path in the tape's VM state. This can be used
  to execute secondary functions contained in a cell's module.

  ## Examples

      iex> %FB.Tape{cells: [
      ...>   %FB.Cell{ref: "test", script: "m = {}; m.sum = function(ctx, a) return ctx + a end; return m"}
      ...> ]}
      ...> |> FB.Tape.load!
      ...> |> FB.Tape.exec("test.sum", [4, 5])
      {:ok, 9}
  """
  @spec exec(t, VM.lua_path, list) :: {:ok, VM.lua_output} | {:error, String.t}
  def exec(tape, path, args \\ [])

  def exec(tape, path, args) when is_binary(path) do
    exec(tape, String.split(path, "."), args)
  end

  def exec(tape, path, args) when is_atom(path) do
    exec(tape, [path], args)
  end

  def exec(tape, path, args) when is_list(path) do
    VM.exec(tape.vm, [:_cell | path], args)
  end


  @doc """
  As `f:FB.Tape.exec/3`, but returns the result or raises an exception.

  ## Examples

      ## Examples

      iex> %FB.Tape{cells: [
      ...>   %FB.Cell{ref: "test", script: "m = {}; m.div = function(ctx, a) return ctx / a end; return m"}
      ...> ]}
      ...> |> FB.Tape.load!
      ...> |> FB.Tape.exec!("test.div", [5, 2])
      2.5
  """
  @spec exec!(t, VM.lua_path, list) :: VM.lua_output
  def exec!(tape, path, args \\ []) do
    case exec(tape, path, args) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Loads the tape with the given VM state (or initialises a new state), and loads
  all the modules from the tape's cells.

  A tape must always be loaded prior to running or executing functions.
  """
  @spec load(t, VM.vm) :: {:ok, t} | {:error, t}
  def load(tape, vm \\ VM.init) do
    case Enum.reduce_while(tape.cells, tape.vm || vm, fn(cell, vm) ->
      #ref = "cell_#{cell.ref}"
      case VM.require(vm, cell.ref, cell.script) do
        {:ok, vm} -> {:cont, vm}
        err       -> {:halt, err}
      end
    end) do
      {:error, err} -> {:error, Map.put(tape, :error, err)}
      vm            -> {:ok, Map.put(tape, :vm, vm)}
    end
  end

  
  @doc """
  As `f:FB.Tape.load/2`, but returns the tape or raises an exception.
  """
  @spec load!(t, VM.vm) :: t
  def load!(tape, vm \\ VM.init) do
    case load(tape, vm) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  Runs the given tape in the given VM state.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context passed to the first cell procedure.
  Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell
  has an error the entire tape fails. Disable strict mode by setting to `false`.

  ## Examples

      iex> {:ok, tape} = %FB.Tape{cells: [
      ...>   %FB.Cell{ref: "a", script: "m = {}; m.main = function(ctx, a) return (ctx or '') .. a end; return m", params: ["b"]},
      ...>   %FB.Cell{ref: "b", script: "m = {}; m.main = function(ctx, a) return (ctx or '') .. a end; return m", params: ["c"]},
      ...>   %FB.Cell{ref: "c", script: "m = {}; m.main = function(ctx) return string.reverse(ctx) end; return m", params: []}
      ...> ]}
      ...> |> FB.Tape.load!
      ...> |> FB.Tape.run(context: "a")
      ...> tape.result
      "cba"
  """
  @spec run(t, keyword) :: {:ok, t} | {:error, t}
  def run(tape, options \\ []) do
    context = Keyword.get(options, :context, nil)
    strict = Keyword.get(options, :strict, true)

    case Enum.reduce_while(tape.cells, context, fn(cell, ctx) ->
      #ref = "cell_#{cell.ref}"
      path = [cell.ref, :main]

      case exec(tape, path, [ctx | cell.params]) do
        {:ok, result} -> {:cont, result}
        err -> if strict, do: {:halt, err}, else: {:cont, ctx}
      end
    end) do
      {:error, error} -> {:error, Map.put(tape, :error, error)}
      result -> {:ok, Map.put(tape, :result, result)}
    end
  end


  @doc """
  As `f:FB.Tape.run/3`, but returns the tape or raises an exception.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context passed to the first cell procedure.
  Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell
  has an error the entire tape fails. Disable strict mode by setting to `false`.

  ## Examples

      iex> tape = %FB.Tape{cells: [
      ...>   %FB.Cell{ref: "a", script: "m = {}; m.main = function(ctx, a) return (ctx or '') .. a end; return m", params: ["b"]},
      ...>   %FB.Cell{ref: "b", script: "m = {}; m.main = function(ctx, a) return (ctx or '') .. a end; return m", params: ["c"]},
      ...>   %FB.Cell{ref: "c", script: "m = {}; m.main = function(ctx) return string.reverse(ctx) end; return m", params: []}
      ...> ]}
      ...> |> FB.Tape.load!
      ...> |> FB.Tape.run!(context: "a")
      ...> tape.result
      "cba"
  """
  @spec run!(t, keyword) :: t
  def run!(tape, options \\ []) do
    case run(tape, options) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  Returns a list of procedure references from the given tape's cells.
  """
  def procedure_refs(tape) do
    tape.cells
    |> Enum.map(&(&1.ref))
  end
  
end