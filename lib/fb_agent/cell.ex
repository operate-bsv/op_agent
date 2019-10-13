defmodule FBAgent.Cell do
  @moduledoc """
  A Functional Bitcoin Cell module. A cell represents a single atomic procude
  call. A `t:FBAgent.Cell.t`contains the procedure script and the the procedure's
  parameters. When the cell is executed it returns a result.

  ## Examples

      iex> %FBAgent.Cell{script: "return function(ctx, a, b) return ctx + a + b end", params: [3, 5]}
      ...> |> FBAgent.Cell.exec(FBAgent.VM.init, context: 0)
      {:ok, 8}
  """
  alias FBAgent.VM

  @typedoc "Procedure Cell"
  @type t :: %__MODULE__{
    ref: String.t,
    script: String.t,
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

      iex> %FBAgent.Cell{script: "return function(ctx) return ctx..' world' end", params: []}
      ...> |> FBAgent.Cell.exec(FBAgent.VM.init, context: "hello")
      {:ok, "hello world"}
  """
  @spec exec(t, VM.t, keyword) :: {:ok, VM.lua_output} | {:error, String.t}
  def exec(cell, vm, options \\ []) do
    ctx = Keyword.get(options, :context, nil)
    case VM.eval(vm, cell.script) do
      {:ok, function} -> VM.exec_function(function, [ctx | cell.params])
      err -> err
    end
  end

  
  @doc """
  As `f:FBAgent.Cell.exec/3`, but returns the result or raises an exception.

  ## Options

  The accepted options are:

  * `:context` - Specifiy the context which is always the first parameter in the
  executed function. Defaults to `nil`.

  ## Examples

      iex> %FBAgent.Cell{script: "return function(ctx) return ctx..' world' end", params: []}
      ...> |> FBAgent.Cell.exec!(FBAgent.VM.init, context: "hello")
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