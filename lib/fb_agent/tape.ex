defmodule FBAgent.Tape do
  @moduledoc """
  Functional Bitcoin Data Tape.

  A tape is is made up of one or more cells, where each cell contains a single
  atomic procedure call.

  When a tape is run, each cell is executed in turn, with the result from each
  cell being passed as the "state" to the next cell. Each cell, or each function,
  manipulates and returns a new state, until the final cell in the tape returns
  the final state or result of the tape.

  ## Examples

      iex> {:ok, tape} = %FBAgent.Tape{cells: [
      ...>   %FBAgent.Cell{script: "return function(state, a) return (state or 0) + a end", params: [2]},
      ...>   %FBAgent.Cell{script: "return function(state, a) return (state or 0) + a end", params: [3]},
      ...>   %FBAgent.Cell{script: "return function(state, a) return (state or 0) + a end", params: [4]}
      ...> ]}
      ...> |> FBAgent.Tape.run(FBAgent.VM.init)
      ...> tape.result
      9
  """
  alias FBAgent.{BPU, Cell, Function, VM}

  @typedoc "Data Tape"
  @type t :: %__MODULE__{
    tx: map,
    index: integer,
    cells: [Cell.t, ...],
    result: VM.lua_output,
    error: binary
  }

  defstruct tx: nil, index: nil, cells: [], result: nil, error: nil


  @doc """
  Converts the given `t:FBAgent.BPU.Transaction.t` into a `t:FBAgent.Tape.t`.
  Returns the result in an OK/Error tuple pair.

  Optionally specifcy the output index of the tape. If not specified, the first
  `OP_RETURN` output is returned as the tape.
  """
  @spec from_bpu(BPU.Transaction.t, integer | nil) ::
    {:ok, __MODULE__.t} |
    {:error, String.t}
  def from_bpu(tx, index \\ nil)

  def from_bpu(%BPU.Transaction{} = tx, index) when is_nil(index) do
    index = Enum.find_index(tx.out, &op_return_output?/1)
    from_bpu(tx, index)
  end

  def from_bpu(%BPU.Transaction{} = tx, index) when is_integer(index) do
    with cells when is_list(cells) <-
      tx.out
      |> Enum.at(index)
      |> Map.get(:tape)
      |> Enum.reject(&op_return_cell?/1)
      |> Enum.map(&Cell.from_bpu!/1)
    do
      tape = struct(__MODULE__, [
        tx: tx,
        index: index,
        cells: cells
      ])
      {:ok, tape}
    else
      error -> error
    end
  end


  @doc """
  As `f:from_bpu/1`, but returns the result or raises an exception.
  """
  @spec from_bpu!(BPU.Transaction.t, integer) :: __MODULE__.t
  def from_bpu!(%BPU.Transaction{} = tx, index \\ nil) do
    case from_bpu(tx, index) do
      {:ok, tape} -> tape
      {:error, err} -> raise err
    end
  end


  @doc """
  Sets the given procedure scripts into the cells of the given tape. If a map of
  aliases is specifed, this is used to reverse map any procedure scripts onto
  aliased cells.
  """
  @spec set_cell_procs(__MODULE__.t, [Function.t, ...], map) :: __MODULE__.t
  def set_cell_procs(tape, procs, aliases \\ %{})

  def set_cell_procs(%__MODULE__{} = tape, [], _aliases), do: tape

  def set_cell_procs(%__MODULE__{} = tape, [%Function{} = f | tail], aliases) do
    ref = case Enum.find(aliases, fn {_k, v} -> v == f.ref end) do
      {k, _v} -> k
      _ -> f.ref
    end

    cells = tape.cells
    |> Enum.map(& put_cell_script(&1, ref, f.script))

    Map.put(tape, :cells, cells)
    |> set_cell_procs(tail, aliases)
  end


  @doc """
  Runs the given tape in the given VM state.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state passed to the first cell procedure.
  Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell
  has an error the entire tape fails. Disable strict mode by setting to `false`.

  ## Examples

      iex> {:ok, tape} = %FBAgent.Tape{cells: [
      ...>   %FBAgent.Cell{script: "return function(state, a) return (state or '') .. a end", params: ["b"]},
      ...>   %FBAgent.Cell{script: "return function(state, a) return (state or '') .. a end", params: ["c"]},
      ...>   %FBAgent.Cell{script: "return function(state) return string.reverse(state) end", params: []}
      ...> ]}
      ...> |> FBAgent.Tape.run(FBAgent.VM.init, state: "a")
      ...> tape.result
      "cba"
  """
  @spec run(__MODULE__.t, VM.t, keyword) ::
    {:ok, __MODULE__.t} |
    {:error, __MODULE__.t}
  def run(%__MODULE__{} = tape, vm, options \\ []) do
    state = Keyword.get(options, :state, nil)
    strict = Keyword.get(options, :strict, true)
    vm = vm
    |> VM.set!("ctx.tx", tape.tx)
    |> VM.set!("ctx.tape_index", tape.index)
    
    case Enum.reduce_while(tape.cells, state, fn(cell, state) ->
      case Cell.exec(cell, vm, state: state) do
        {:ok, result}   -> {:cont, result}
        {:error, error} ->
          if strict, do: {:halt, {:error, error}}, else: {:cont, state}
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

  * `:state` - Specifiy the state passed to the first cell procedure.
  Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell
  has an error the entire tape fails. Disable strict mode by setting to `false`.
  """
  @spec run!(__MODULE__.t, VM.t, keyword) :: __MODULE__.t
  def run!(%__MODULE__{} = tape, vm, options \\ []) do
    case run(tape, vm, options) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  Validates the given tape. Returns true if all the tape's cells are valid.
  """
  @spec valid?(__MODULE__.t) :: boolean
  def valid?(%__MODULE__{} = tape) do
    tape.cells
    |> Enum.all?(&(Cell.valid?(&1)))
  end


  @doc """
  Returns a list of procedure references from the given tape's cells. If a map
  of aliases is specifed, this is used to alias references to alternative values.

  ## Examples

      iex> %FBAgent.Tape{cells: [
      ...>   %FBAgent.Cell{ref: "aabbccdd"},
      ...>   %FBAgent.Cell{ref: "eeff1122"},
      ...>   %FBAgent.Cell{ref: "33445500"}
      ...> ]}
      ...> |> FBAgent.Tape.get_cell_refs(%{"33445500" => "MyAliasReference"})
      ["aabbccdd", "eeff1122", "MyAliasReference"]
  """
  @spec get_cell_refs(__MODULE__.t, map) :: list
  def get_cell_refs(%__MODULE__{} = tape, aliases \\ %{}) do
    tape.cells
    |> Enum.map(&(&1.ref))
    |> Enum.uniq
    |> Enum.map(& Map.get(aliases, &1, &1))
  end


  # Private: Returns true of the BPU Script is an OP_RETURN script
  defp op_return_output?(%BPU.Script{tape: tape}),
    do: List.first(tape) |> op_return_cell?

  defp op_return_cell?(%BPU.Cell{cell: cells}),
    do: cells |> Enum.any?(& get_in(&1, [:op]) == 106)


  # Private: Puts the given script into the cell if the specfied ref matches
  defp put_cell_script(cell, ref, script) do
    case cell.ref do
      ^ref -> Map.put(cell, :script, script)
      _ -> cell
    end
  end
  
end