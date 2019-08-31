defmodule FB.Cell do
  @moduledoc """
  A Functional Bitcoin Cell module. A cell represents a single atomic procude
  call. A `t:FB.Cell.t`contains the procedure script and the the procedure's
  parameters. When the cell is executed it returns a result.

  ## Examples

      iex> %FB.Cell{
      ...>   ref: "test",
      ...>   script: "local m = {}; m.main = function(ctx, a, b) return ctx + a + b end; return m",
      ...>   params: [3, 5]
      ...> }
      ...> |> FB.Cell.exec(FB.VM.init, context: 0)
      {:ok, 8}
  """
  alias FB.VM

  @typedoc "Procedure Cell"
  @type t :: %__MODULE__{
    ref: String.t,
    script: String.t,
    params: list
  }

  defstruct ref: nil, script: nil, params: []

  @doc """
  Executes the given cell in the given VM state.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %FB.Cell{
      ...>   ref: "test",
      ...>   script: "local m = {}; m.main = function(ctx) return ctx..' world' end; return m",
      ...>   params: []
      ...> }
      ...> |> FB.Cell.exec(FB.VM.init, context: "hello")
      {:ok, "hello world"}
  """
  @spec exec(t, VM.vm, keyword) :: {:ok, VM.lua_output} | {:error, String.t}
  def exec(cell, vm, options \\ []) do
    path = Keyword.get(options, :path, "main")
    ctx = Keyword.get(options, :context, nil)
    #ref = "cell_#{cell.ref}"

    case VM.require(vm, cell.ref, cell.script) do
      {:ok, vm} -> VM.exec(vm, [:_cell, cell.ref, path], [ctx | cell.params])
      err -> err
    end
  end

  
  @doc """
  As `f:FB.Cell.exec/3`, but returns the result or raises an exception.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %FB.Cell{
      ...>   ref: "test",
      ...>   script: "local m = {}; m.main = function(ctx) return ctx..' world' end; return m",
      ...>   params: []
      ...> }
      ...> |> FB.Cell.exec!(FB.VM.init, context: "hello")
      "hello world"
  """
  @spec exec!(t, VM.vm, keyword) :: VM.lua_output
  def exec!(cell, vm, options \\ []) do
    case exec(cell, vm, options) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end
  
end