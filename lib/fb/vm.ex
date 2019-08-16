defmodule FB.VM do
  @moduledoc """
  Functional Bitcoin VM module. Responsible for initalizing the Lua state and executing scripts.
  """

  @typedoc "Functional Bitcoin VM state"
  @type vm :: tuple

  @default_handler :main
  @extensions [
    FB.VM.JsonExtension
  ]
  

  @doc """
  Initliazes a new VM state.

  ## Options

  The accepted options are:

  * `:extend_with` - Provide a list of modules with which to extend the VM state.

  ## Examples

      iex> vm = FB.VM.init
      ...> elem(vm, 0) == :luerl
      true
  """
  @spec init(keyword) :: vm
  def init(options \\ []) do
    extensions = @extensions
    |> Enum.concat(Keyword.get(options, :extend_with, []))

    Sandbox.init
    |> extend(extensions)
  end

  
  @doc """
  Extends the VM state with the given module or modules.

  ## Examples

      FB.VM.extend(vm, [MyLuaExtension, OtherExtension])
  """
  @spec extend(vm, [module] | module) :: vm
  def extend(vm, [module | tail]) do
    extend(vm, module)
    |> extend(tail)
  end

  def extend(vm, []), do: vm

  def extend(vm, module) when is_atom(module) do
    apply(module, :setup, [vm])
  end


  @doc """
  Evaluates the given script within the VM state and returns its result.

  ## Examples

      iex> FB.VM.init
      ...> |> FB.VM.eval("return 'hello world'")
      {:ok, "hello world"}

      iex> FB.VM.init
      ...> |> FB.VM.eval("return 2 / 3")
      {:ok, 0.6666666666666666}
  """
  @spec eval(vm, binary) :: {:ok, binary | number | list | map} | {:error, binary}
  def eval(vm, code) do
    case :luerl.eval(code, vm) do
      {:ok, result} -> {:ok, decode(result)}
      {:error, err} -> {:error, "Lua Sandbox error: #{inspect err}"}
    end
  end


  @doc """
  As `f:FB.VM.eval/2`, but returns the result or raises an exception.
  
  ## Examples

      iex> FB.VM.init
      ...> |> FB.VM.eval!("return 'hello world'")
      "hello world"
  """
  @spec eval!(vm, binary) :: binary | number | list | map
  def eval!(vm, code) do
    case eval(vm, code) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Evaluates the given script within the VM state, and executes a handler function.

  ## Options

  The accepted options are:

  * `:handler` - Specify the handler function. Defaults to `:main`.

  ## Examples

      iex> FB.VM.init
      ...> |> FB.VM.exec("function main() return 'hello world' end")
      {:ok, "hello world"}

      iex> FB.VM.init
      ...> |> FB.VM.exec("function main(a, b) return a * b end", [2, 3])
      {:ok, 6}

      iex> FB.VM.init
      ...> |> FB.VM.exec("function sum(a, b) return a + b end", [2, 3], handler: :sum)
      {:ok, 5}
  """
  @spec exec(vm, binary, list, keyword) :: {:ok, binary | number | list | map} | {:error, binary}
  def exec(vm, script, args \\ [], options \\ []) do
    path = case Keyword.get(options, :handler, @default_handler) do
      handler when is_atom(handler) -> [handler]
      handler when is_list(handler) -> handler
    end

    try do
      vm = Sandbox.play!(vm, script)
      result = :luerl.call_function(path, args, vm)
      |> elem(0)
      {:ok, decode(result)}
    rescue
      err -> {:error, "Lua Sandbox error: #{inspect err.original}"}
    end
  end


  @doc """
  As `f:FB.VM.exec/4`, but returns the result or raises an exception.
  
  ## Examples

      iex> FB.VM.init
      ...> |> FB.VM.exec!("function main() return 'hello world' end")
      "hello world"
  """
  @spec exec!(vm, binary, list, keyword) :: binary | number | list | map
  def exec!(vm, code, args \\ [], options \\ []) do
    case exec(vm, code, args, options) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Decodes a value returned from the VM state into an Elixir type.
  Automatically detects when 64 bit long numbers can be converted to integers,
  and handles converting Lua tables into either Elixir lists or maps.

  ## Examples

      iex> FB.VM.decode(23.23)
      23.23

      iex> FB.VM.decode(23.0)
      23

      iex> FB.VM.decode([{"foo", 1}, {"bar", 2}])
      %{"foo" => 1, "bar" => 2}
  """
  @spec decode(binary | number | list) :: binary | number | list | map
  def decode([{key, val}]), do: %{key => val}
  def decode([val]), do: decode(val)

  def decode(val) when is_float(val) do
    case Float.ratio(val) do
      {_, 1} -> trunc(val)
      _ -> val
    end
  end

  def decode(val) when is_list(val) do
    case lua_table_type(val) do
      :list -> Enum.map(val, &(elem(decode(&1), 1)))
      :map  -> Enum.reduce(val, %{}, fn({k,v},map) -> Map.put(map, k, decode(v)) end)
      _     -> Enum.map(val, &decode/1)
    end
  end

  def decode(val), do: val


  # Private function
  # Determins which method to use to decode the Lue table
  defp lua_table_type(table) do
    cond do
      Enum.all?(table, &(is_tuple(&1))) ->
        case Enum.all?(table, fn {k, v} -> is_integer(k) && !is_list(v) end) do
          true  -> :list
          false -> :map
        end
      true -> false
    end
  end
  
end