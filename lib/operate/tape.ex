defmodule Operate.Tape do
  @moduledoc """
  Module for working with Operate tapes.

  An Operate program is a tape made up of one or more cells, where each cell
  contains a single atomic procedure call (known as an "Op").

  When a tape is run, each cell is executed in turn, with the result from each
  cell is passed to the next cell. This is known as the "state". Each cell
  returns a new state, until the final cell in the tape returns the result of
  the tape.

  ## Examples

      iex> {:ok, tape} = %Operate.Tape{cells: [
      ...>   %Operate.Cell{op: "return function(state, a) return (state or 0) + a end", params: [2]},
      ...>   %Operate.Cell{op: "return function(state, a) return (state or 0) + a end", params: [3]},
      ...>   %Operate.Cell{op: "return function(state, a) return (state or 0) + a end", params: [4]}
      ...> ]}
      ...> |> Operate.Tape.run(Operate.VM.init)
      ...> tape.result
      9
  """
  alias Operate.{BPU, Cell, Op, VM}

  @typedoc "Operate Tape"
  @type t :: %__MODULE__{
    tx: BPU.Transaction,
    index: integer,
    cells: [Cell.t, ...],
    result: VM.lua_output,
    error: binary
  }

  defstruct tx: nil, index: nil, cells: [], result: nil, error: nil


  @doc """
  Converts the given `t:Operate.BPU.Transaction.t/0` into a `t:Operate.Tape.t/0`.
  Returns the result in an `:ok` / `:error` tuple pair.

  Optionally specifcy the output index of the tape. If not specified, the first
  `OP_RETURN` output is returned as the tape.
  """
  @spec from_bpu(BPU.Transaction.t, integer | nil) ::
    {:ok, __MODULE__.t} |
    {:error, String.t}
  def from_bpu(tx, index \\ nil)

  def from_bpu(%BPU.Transaction{} = tx, index) when is_nil(index) do
    case Enum.find_index(tx.out, &op_return_output?/1) do
      nil -> {:error, "No tape found in transaction."}
      index -> from_bpu(tx, index)
    end
  end

  def from_bpu(%BPU.Transaction{} = tx, index) when is_binary(index),
    do: from_bpu(tx, String.to_integer(index))

  def from_bpu(%BPU.Transaction{} = tx, index) when is_integer(index) do
    with  output when not is_nil(output) <- Enum.at(tx.out, index),
          true <- op_return_output?(output),
          cells when is_list(cells) <-
            output
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
      {:error, _} = error -> error
      _ -> {:error, "No tape found in transaction."}
    end
  end


  @doc """
  As `from_bpu/1`, but returns the result or raises an exception.
  """
  @spec from_bpu!(BPU.Transaction.t, integer) :: __MODULE__.t
  def from_bpu!(%BPU.Transaction{} = tx, index \\ nil) do
    case from_bpu(tx, index) do
      {:ok, tape} -> tape
      {:error, err} -> raise err
    end
  end


  @doc """
  Sets the given Ops into the cells of the given tape. If a map of
  aliases is specifed, this is used to reverse map any procedure scripts onto
  aliased cells.
  """
  @spec set_cell_ops(__MODULE__.t, [Op.t, ...], map) :: __MODULE__.t
  def set_cell_ops(tape, ops, aliases \\ %{})

  def set_cell_ops(%__MODULE__{} = tape, [], _aliases), do: tape

  def set_cell_ops(%__MODULE__{} = tape, [%Op{} = op | tail], aliases) do
    refs = case Enum.filter(aliases, fn {_k, v} -> v == op.ref end) do
      [] -> [op.ref]
      res -> Keyword.keys(res)
    end

    cells = tape.cells
    |> Enum.map(& put_cell_op(&1, refs, op))

    Map.put(tape, :cells, cells)
    |> set_cell_ops(tail, aliases)
  end


  @doc """
  Runs the tape in the given VM state.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state passed to the first cell procedure. Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell has an error the entire tape fails. Disable strict mode by setting to `false`.

  ## Examples

      iex> {:ok, tape} = %Operate.Tape{cells: [
      ...>   %Operate.Cell{op: "return function(state, a) return (state or '') .. a end", params: ["b"]},
      ...>   %Operate.Cell{op: "return function(state, a) return (state or '') .. a end", params: ["c"]},
      ...>   %Operate.Cell{op: "return function(state) return string.reverse(state) end", params: []}
      ...> ]}
      ...> |> Operate.Tape.run(Operate.VM.init, state: "a")
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
    |> VM.set!("tx", tape.tx) # TODO - remove tx in v 0.1.0
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
  As `run/3`, but returns the tape or raises an exception.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state passed to the first cell procedure. Defaults to `nil`.
  * `:strict` - By default the tape runs in struct mode - meaning if any cell has an error the entire tape fails. Disable strict mode by setting to `false`.
  """
  @spec run!(__MODULE__.t, VM.t, keyword) :: __MODULE__.t
  def run!(%__MODULE__{} = tape, vm, options \\ []) do
    case run(tape, vm, options) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  Returns a list of Op references from the tape's cells. If a map of aliases is
  specifed, this is used to alias references to alternative values.

  ## Examples

      iex> %Operate.Tape{cells: [
      ...>   %Operate.Cell{ref: "aabbccdd"},
      ...>   %Operate.Cell{ref: "eeff1122"},
      ...>   %Operate.Cell{ref: "33445500"}
      ...> ]}
      ...> |> Operate.Tape.get_op_refs(%{"33445500" => "MyAliasReference"})
      ["aabbccdd", "eeff1122", "MyAliasReference"]
  """
  @spec get_op_refs(__MODULE__.t, map) :: list
  def get_op_refs(%__MODULE__{} = tape, aliases \\ %{}) do
    tape.cells
    |> Enum.map(&(&1.ref))
    |> Enum.uniq
    |> Enum.map(& Map.get(aliases, &1, &1))
  end


  @doc """
  Validates the given tape. Returns true if all the tape's cells are valid.
  """
  @spec valid?(__MODULE__.t) :: boolean
  def valid?(%__MODULE__{} = tape) do
    tape.cells
    |> Enum.all?(&(Cell.valid?(&1)))
  end


  # Private: Returns true of the BPU Script is an OP_RETURN script
  defp op_return_output?(%BPU.Script{tape: tape}),
    do: List.first(tape) |> op_return_cell?

  defp op_return_cell?(%BPU.Cell{cell: cells}),
    do: cells |> Enum.any?(& get_in(&1, [:op]) == 106 || get_in(&1, ["op"]) == 106)


  # Private: Puts the given script into the cell if the specfied ref matches
  defp put_cell_op(cell, refs, op) do
    case Enum.member?(refs, cell.ref) do
      true -> Map.put(cell, :op, op.fn)
      false -> cell
    end
  end
end
