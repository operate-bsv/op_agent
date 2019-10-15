defmodule FBAgent.Cell do
  @moduledoc """
  A Functional Bitcoin Cell module. A cell represents a single atomic procude
  call. A `t:FBAgent.Cell.t`contains the procedure script and the the procedure's
  parameters. When the cell is executed it returns a result.

  ## Examples

      iex> %FBAgent.Cell{script: "return function(state, a, b) return state + a + b end", params: [3, 5]}
      ...> |> FBAgent.Cell.exec(FBAgent.VM.init, state: 0)
      {:ok, 8}
  """
  alias FBAgent.VM
  alias FBAgent.BPU

  @typedoc "Procedure Cell"
  @type t :: %__MODULE__{
    ref: String.t,
    params: list,
    script: String.t,
    local_index: integer,
    global_index: integer
  }

  defstruct ref: nil, params: [], script: nil, local_index: nil, global_index: nil


  @doc """
  TODOC
  """
  @spec from_bpu(BPU.Cell.t | map) :: {:ok, __MODULE__.t} | {:error, __MODULE__.t}
  def from_bpu(%BPU.Cell{cell: [head | tail]}) do
    str = Base.decode64!(head.b)
    ref = case String.valid?(str) do
      true  -> str
      false -> Base.encode16(str, case: :lower)
    end

    struct(__MODULE__, [
      ref: ref,
      params: Enum.map(tail, &normalize_param/1),
      local_index: head.i,
      global_index: head.ii
    ])
  end

  defp normalize_param(%{b: b}), do: Base.decode64!(b)
  defp normalize_param(_), do: nil



  @doc """
  Executes the given cell in the given VM state.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %FBAgent.Cell{script: "return function(state) return state..' world' end", params: []}
      ...> |> FBAgent.Cell.exec(FBAgent.VM.init, state: "hello")
      {:ok, "hello world"}
  """
  @spec exec(t, VM.t, keyword) :: {:ok, VM.lua_output} | {:error, String.t}
  def exec(cell, vm, options \\ []) do
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
  As `f:FBAgent.Cell.exec/3`, but returns the result or raises an exception.

  ## Options

  The accepted options are:

  * `:state` - Specifiy the state which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %FBAgent.Cell{script: "return function(state) return state..' world' end", params: []}
      ...> |> FBAgent.Cell.exec!(FBAgent.VM.init, state: "hello")
      "hello world"
  """
  @spec exec!(t, VM.t, keyword) :: VM.lua_output
  def exec!(cell, vm, options \\ []) do
    case exec(cell, vm, options) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  TODOC
  """
  def valid?(cell) do
    validate_presence(cell.ref) && validate_presence(cell.script)
  end

  defp validate_presence(val) do
    case val do
      v when is_binary(v) -> String.trim(v) != ""
      nil -> false
      _ -> true
    end
  end
  
end