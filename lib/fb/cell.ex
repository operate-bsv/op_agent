defmodule FB.Cell do
  @moduledoc """
  A Functional Bitcoin Cell module. A cell represents a single atomic procude
  call. A `t:FB.Cell.t`contains the procedure script and the the procedure's
  parameters. When the cell is executed it returns a result.

  ## Examples

      iex> %FB.Cell{script: "function main(ctx, a, b) return ctx + a + b end", params: [3, 5]}
      ...> |> FB.Cell.exec(FB.VM.init, context: 0)
      {:ok, 8}
  """
  alias FB.VM

  @typedoc "Procedure Cell"
  @type t :: %__MODULE__{
    ref: binary,
    script: binary,
    params: list
  }

  defstruct ref: nil, params: [], script: nil

  @doc """
  Executes the given cell in the given VM state.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %FB.Cell{script: "function main(ctx) return ctx..' world' end", params: []}
      ...> |> FB.Cell.exec(FB.VM.init, context: "hello")
      {:ok, "hello world"}
  """
  @spec exec(t, Vm.vm, keyword) :: {:ok, binary | number | list | map} | {:error, binary}
  def exec(cell, vm, options \\ []) do
    ctx = Keyword.get(options, :context, nil)
    VM.exec(vm, cell.script, [ctx | cell.params])
  end

  
  @doc """
  As `f:FB.Cell.exec/3`, but returns the result or raises an exception.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %FB.Cell{script: "function main(ctx) return ctx..' world' end", params: []}
      ...> |> FB.Cell.exec!(FB.VM.init, context: "hello")
      "hello world"
  """
  @spec exec!(t, VM.vm, keyword) :: binary | number | list | map
  def exec!(cell, vm, options \\ []) do
    case exec(cell, vm, options) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end
  
end