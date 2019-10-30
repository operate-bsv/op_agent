defmodule Operate.Cell do
  @moduledoc """
  Functional Bitcoin Procedure Cell.

  A cell represents a single atomic procedure call. A `t:Operate.Cell.t`contains
  the procedure script and the the procedure's parameters. When the cell is
  executed it returns a result.

  ## Examples

      iex> %Operate.Cell{script: "return function(state, a, b) return state + a + b end", params: [3, 5]}
      ...> |> Operate.Cell.exec(Operate.VM.init, state: 1)
      {:ok, 9}
  """
  alias Operate.{BPU, VM}

  @typedoc "Procedure Cell"
  @type t :: %__MODULE__{
    ref: String.t,
    params: list,
    script: String.t,
    local_index: integer,
    global_index: integer
  }

  defstruct ref: nil,
            params: [],
            script: nil,
            local_index: nil,
            global_index: nil


  @doc """
  Converts the given `t:Operate.BPU.Cell.t` into a `t:Operate.Cell.t`. Returns
  the result in an OK/Error tuple pair.
  """
  @spec from_bpu(BPU.Cell.t) ::
    {:ok, __MODULE__.t} |
    {:error, String.t}
  def from_bpu(%BPU.Cell{cell: [head | tail]}) do
    with {:ok, str} <- Base.decode64(head.b),
         params when is_list(params) <- Enum.map(tail, &normalize_param/1)
    do
      ref = case String.valid?(str) do
        true  -> str
        false -> Base.encode16(str, case: :lower)
      end

      cell = struct(__MODULE__, [
        ref: ref,
        params: params,
        local_index: head.i,
        global_index: head.ii
      ])
      {:ok, cell}
    else
      error -> error
    end 
  end


  @doc """
  As `f:from_bpu/1`, but returns the result or raises an exception.
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

  * `:state` - Specifiy the state which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %Operate.Cell{script: "return function(state) return state..' world' end", params: []}
      ...> |> Operate.Cell.exec(Operate.VM.init, state: "hello")
      {:ok, "hello world"}
  """
  @spec exec(__MODULE__.t, VM.t, keyword) ::
    {:ok, VM.lua_output} |
    {:error, String.t}
  def exec(%__MODULE__{} = cell, vm, options \\ []) do
    state = Keyword.get(options, :state, nil)
    vm = vm
    |> VM.set!("ctx.local_index", cell.local_index)
    |> VM.set!("ctx.global_index", cell.global_index)

    case VM.eval(vm, cell.script) do
      {:ok, function} -> VM.exec_function(function, [state | cell.params])
      err -> err
    end
  end

  
  @doc """
  As `f:Operate.Cell.exec/3`, but returns the result or raises an exception.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state which is always the first parameter in the
  executed function. Defaults to `nil`.
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

      iex> %Operate.Cell{ref: "abc", script: "return 123"}
      ...> |> Operate.Cell.valid?
      true

      iex> %Operate.Cell{}
      ...> |> Operate.Cell.valid?
      false
  """
  @spec valid?(__MODULE__.t) :: boolean
  def valid?(%__MODULE__{} = cell) do
    [:ref, :script]
    |> Enum.all?(& Map.get(cell, &1) |> validate_presence)
  end


  # Private: Normalizes the cell param
  defp normalize_param(%{b: b}), do: Base.decode64!(b)
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