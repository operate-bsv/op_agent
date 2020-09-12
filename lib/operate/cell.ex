defmodule Operate.Cell do
  @moduledoc """
  Module for working with Operate tape cells.

  A cell represents a single atomic procedure call. A `t:Operate.Cell.t/0`
  contains the Op script and parameters. When the cell is executed it returns a
  result.

  ## Examples

      iex> %Operate.Cell{op: "return function(state, a, b) return state + a + b end", params: [3, 5]}
      ...> |> Operate.Cell.exec(Operate.VM.init, state: 1)
      {:ok, 9}
  """
  alias Operate.{BPU, VM}

  @typedoc "Operate Cell"
  @type t :: %__MODULE__{
    ref: String.t,
    params: list,
    op: String.t,
    index: integer,
    data_index: integer
  }

  defstruct ref: nil,
            params: [],
            op: nil,
            index: nil,
            data_index: nil


  @doc """
  Converts the given `t:Operate.BPU.Cell.t/0` into a `t:Operate.Cell.t/0`. Returns
  the result in an `:ok` / `:error` tuple pair.
  """
  @spec from_bpu(BPU.Cell.t) ::
    {:ok, __MODULE__.t} |
    {:error, String.t}
  def from_bpu(%BPU.Cell{cell: [head | tail], i: index}) do
    head = case Enum.all?(head, fn({k, _}) -> is_atom(k) end) do
      true -> head
      false ->
        for {key, val} <- head, into: %{}, do: {String.to_atom(key), val}
    end

    with {:ok, str} <- Base.decode64(head.b),
         params when is_list(params) <- Enum.map(tail, &normalize_param/1)
    do
      # TODO - in future use h attribute of BOB2
      ref = case byte_size(str) do
        s when s == 4 or s == 32 -> Base.encode16(str, case: :lower)
        _ -> str
      end

      cell = struct(__MODULE__, [
        ref: ref,
        params: params,
        index: index,
        data_index: head.ii
      ])
      {:ok, cell}
    else
      error -> error
    end
  end


  @doc """
  As `from_bpu/1`, but returns the result or raises an exception.
  """
  @spec from_bpu!(BPU.Cell.t) :: __MODULE__.t
  def from_bpu!(%BPU.Cell{} = cell) do
    case from_bpu(cell) do
      {:ok, cell} -> cell
      {:error, err} -> raise err
    end
  end


  @doc """
  Executes the given cell in the given VM state.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state which is always the first parameter in the executed function. Defaults to `nil`.

  ## Examples

      iex> %Operate.Cell{op: "return function(state) return state..' world' end", params: []}
      ...> |> Operate.Cell.exec(Operate.VM.init, state: "hello")
      {:ok, "hello world"}
  """
  @spec exec(__MODULE__.t, VM.t, keyword) ::
    {:ok, VM.lua_output} |
    {:error, String.t}
  def exec(%__MODULE__{} = cell, vm, options \\ []) do
    state = Keyword.get(options, :state, nil)
    vm = vm
    |> VM.set!("ctx.cell_index", cell.index)
    |> VM.set!("ctx.data_index", cell.data_index)
    |> VM.set!("ctx.global_index", cell.data_index) # TODO - remove global_index in v 0.1.0

    case VM.eval(vm, cell.op) do
      {:ok, function} -> VM.exec_function(function, [state | cell.params])
      err -> err
    end
  end


  @doc """
  As `exec/3`, but returns the result or raises an exception.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state which is always the first parameter in the executed function. Defaults to `nil`.
  """
  @spec exec!(__MODULE__.t, VM.t, keyword) :: VM.lua_output
  def exec!(%__MODULE__{} = cell, vm, options \\ []) do
    case exec(cell, vm, options) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Validates the given cell. Returns true if the cell has a reference and script.

  ## Examples

      iex> %Operate.Cell{ref: "abc", op: "return 123"}
      ...> |> Operate.Cell.valid?
      true

      iex> %Operate.Cell{}
      ...> |> Operate.Cell.valid?
      false
  """
  @spec valid?(__MODULE__.t) :: boolean
  def valid?(%__MODULE__{} = cell) do
    [:ref, :op]
    |> Enum.all?(& Map.get(cell, &1) |> validate_presence)
  end


  # Private: Normalizes the cell param
  defp normalize_param(%{b: b}), do: Base.decode64!(b)
  defp normalize_param(%{"b" => b}), do: Base.decode64!(b)
  defp normalize_param(_), do: nil


  # Private: Checks the given value is not nil or empty
  defp validate_presence(val) do
    case val do
      v when is_binary(v) -> String.trim(v) != ""
      nil -> false
      _ -> true
    end
  end

end
