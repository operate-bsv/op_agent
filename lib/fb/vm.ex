defmodule FB.VM do
  @moduledoc """
  Functional Bitcoin VM module. Responsible for initalizing the Lua state and
  executing scripts.
  """

  @typedoc "Functional Bitcoin VM state"
  @type vm :: tuple

  @typedoc "Functional Bitcoin return value"
  @type lua_output :: binary | number | list | map

  @typedoc "Function reference. Either a dot-delimited string or list of strings or atoms."
  @type lua_path :: atom | String.t | list

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
    |> Sandbox.set!("_cell", [])
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
  TODO

  ## Examples

      FB.VM.init
      FB.VM.require("m", "local m = {}; m.hello = function(txt) return 'Hello '..txt end; return m")
      {:ok, {:luerl, ...}}
  """
  @spec require(vm, String.t, String.t) :: vm
  def require(vm, name, code) do
    Sandbox.play(vm, "_cell['#{name}'] = (function()\n#{code}\nend)()")
  end


  @doc """
  TODO

  ## Examples

      iex> FB.VM.init
      ...> |> FB.VM.require!("m", "local m = {}; m.hello = function(txt) return 'Hello '..txt end; return m")
      ...> |> FB.VM.exec("_cell.m.hello", ["world"])
      {:ok, "Hello world"}
  """
  @spec require!(vm, String.t, String.t) :: vm
  def require!(vm, name, code) do
    Sandbox.play!(vm, "_cell['#{name}'] = (function()\n#{code}\nend)()")
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
  @spec eval(vm, String.t) :: {:ok, lua_output} | {:error, String.t}
  def eval(vm, code) do
    case :luerl.eval(code, vm) do
      {:ok, result} -> {:ok, decode(result)}
      {:error, err} ->
        #{err_type, err, _vm} = err.original
        #{:error, "Lua Error: #{inspect {err_type, err}}"}
        {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `f:FB.VM.eval/2`, but returns the result or raises an exception.
  
  ## Examples

      iex> FB.VM.init
      ...> |> FB.VM.eval!("return 'hello world'")
      "hello world"
  """
  @spec eval!(vm, String.t) :: lua_output
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
      ...> |> Sandbox.play!("function main() return 'hello world' end")
      ...> |> FB.VM.exec(:main)
      {:ok, "hello world"}

      iex> FB.VM.init
      ...> |> Sandbox.play!("function main(a, b) return a * b end")
      ...> |> FB.VM.exec("main", [2, 3])
      {:ok, 6}

      iex> FB.VM.init
      ...> |> Sandbox.play!("function sum(a, b) return a + b end")
      ...> |> FB.VM.exec(:sum, [2, 3])
      {:ok, 5}
  """
  @spec exec(vm, atom | String.t | list, list) :: {:ok, lua_output} | {:error, String.t}
  def exec(vm, path, args \\ [])

  def exec(vm, path, args) when is_binary(path) do
    exec(vm, String.split(path, "."), args)
  end

  def exec(vm, path, args) when is_atom(path) do
    exec(vm, [path], args)
  end

  def exec(vm, path, args) when is_list(path) do
    try do
      result = :luerl.call_function(path, args, vm)
      |> elem(0)
      {:ok, decode(result)}
    rescue
      err -> 
        #{err_type, err, _vm} = err.original
        #{:error, "Lua Error: #{inspect {err_type, err}}"}
        {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `f:FB.VM.exec/4`, but returns the result or raises an exception.
  
  ## Examples

      iex> FB.VM.init
      ...> |> Sandbox.play!("function main() return 'hello world' end")
      ...> |> FB.VM.exec!(:main)
      "hello world"
  """
  @spec exec!(vm, atom | String.t | list, list) :: lua_output
  def exec!(vm, path, args \\ []) do
    case exec(vm, path, args) do
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
  @spec decode(binary | number | list) :: lua_output
  def decode([{key, val}]), do: %{key => decode(val)}
  def decode([val]), do: decode(val)

  def decode(val) when is_float(val) do
    case Float.ratio(val) do
      {_, 1} -> trunc(val)
      _ -> val
    end
  end

  def decode(val) when is_list(val) do
    case lua_table_type(val) do
      :list -> Enum.map(val, &(elem(&1, 1) |> decode))
      :map  -> Enum.reduce(val, %{}, fn({k,v}, map) -> Map.put(map, k, decode(v)) end)
      _     -> Enum.map(val, &decode/1)
    end
  end

  def decode(val), do: val


  # Private function
  # Determins which method to use to decode the Lue table
  defp lua_table_type(table) do
    cond do
      Enum.all?(table, &(is_tuple(&1))) ->
        case Enum.all?(table, &(elem(&1, 0) |> is_integer)) do
          true  -> :list
          false -> :map
        end
      true -> false
    end
  end
  
end