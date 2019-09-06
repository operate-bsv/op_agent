defmodule FBAgent.VM do
  @moduledoc """
  Functional Bitcoin VM module. Responsible for initalizing the Lua state and
  executing scripts.
  """

  @typedoc "Functional Bitcoin VM state"
  @type vm :: tuple

  @typedoc "Function reference. Either a dot-delimited string or list of strings or atoms."
  @type lua_path :: atom | String.t | list

  @typedoc "Functional Bitcoin return value"
  @type lua_output :: binary | number | list | map

  @extensions [
    FBAgent.VM.JsonExtension
  ]
  

  @doc """
  Initliazes a new VM state.

  ## Options

  The accepted options are:

  * `:extensions` - Provide a list of modules with which to extend the VM state.

  ## Examples

      iex> vm = FBAgent.VM.init
      ...> elem(vm, 0) == :luerl
      true
  """
  @spec init(keyword) :: vm
  def init(options \\ []) do
    extensions = @extensions
    |> Enum.concat(Keyword.get(options, :extensions, []))

    Sandbox.init
    |> extend(extensions)
  end

  
  @doc """
  Extends the VM state with the given module or modules.

  ## Examples

      FBAgent.VM.extend(vm, [MyLuaExtension, OtherExtension])
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
  Evaluates the given script within the VM state and returns the result.

  ## Examples

      iex> FBAgent.VM.init
      ...> |> FBAgent.VM.eval("return 'hello world'")
      {:ok, "hello world"}

      iex> FBAgent.VM.init
      ...> |> FBAgent.VM.eval("return 2 / 3")
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
  As `f:FBAgent.VM.eval/2`, but returns the result or raises an exception.
  
  ## Examples

      iex> FBAgent.VM.init
      ...> |> FBAgent.VM.eval!("return 'hello world'")
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
  Calls a function within the VM state at the given lua path and returns the result.

  ## Examples

      iex> FBAgent.VM.init
      ...> |> Sandbox.play!("function main() return 'hello world' end")
      ...> |> FBAgent.VM.call(:main)
      {:ok, "hello world"}

      iex> FBAgent.VM.init
      ...> |> Sandbox.play!("function main(a, b) return a * b end")
      ...> |> FBAgent.VM.call("main", [2, 3])
      {:ok, 6}

      iex> FBAgent.VM.init
      ...> |> Sandbox.play!("function sum(a, b) return a + b end")
      ...> |> FBAgent.VM.call(:sum, [2, 3])
      {:ok, 5}
  """
  @spec call(vm, lua_path, list) :: {:ok, lua_output} | {:error, String.t}
  def call(vm, path, args \\ [])

  def call(vm, path, args) when is_binary(path) do
    call(vm, String.split(path, "."), args)
  end

  def call(vm, path, args) when is_atom(path) do
    call(vm, [path], args)
  end

  def call(vm, path, args) when is_list(path) do
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
  As `f:FBAgent.VM.call/3`, but returns the result or raises an exception.
  
  ## Examples

      iex> FBAgent.VM.init
      ...> |> Sandbox.play!("function main() return 'hello world' end")
      ...> |> FBAgent.VM.call!(:main)
      "hello world"
  """
  @spec call!(vm, lua_path, list) :: lua_output
  def call!(vm, path, args \\ []) do
    case call(vm, path, args) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Executes the given function with the given arguments.

  ## Examples

      iex> FBAgent.VM.init
      ...> |> FBAgent.VM.eval!("return function(a,b) return a * b end")
      ...> |> FBAgent.VM.exec([3,4])
      {:ok, 12}
  """
  @spec exec(function, list) :: {:ok, lua_output} | {:error, String.t}
  def exec(function, args \\ []) do
    try do
      result = apply(function, [args])
      |> decode
      {:ok, result}
    rescue
      err ->
        {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `f:FBAgent.VM.exec/2`, but returns the result or raises an exception.

  ## Examples

      iex> FBAgent.VM.init
      ...> |> FBAgent.VM.eval!("return function(a,b) return a .. ' ' .. b end")
      ...> |> FBAgent.VM.exec!(["hello", "world"])
      "hello world"
  """
  @spec exec!(function, list) :: lua_output
  def exec!(function, args \\ []) do
    case exec(function, args) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Decodes a value returned from the VM state into an Elixir type.
  Automatically detects when 64 bit long numbers can be converted to integers,
  and handles converting Lua tables into either Elixir lists or maps.

  ## Examples

      iex> FBAgent.VM.decode(23.23)
      23.23

      iex> FBAgent.VM.decode(23.0)
      23

      iex> FBAgent.VM.decode([{"foo", 1}, {"bar", 2}])
      %{"foo" => 1, "bar" => 2}
  """
  @spec decode(binary | number | list) :: lua_output

  def decode([{key, val}]) do
    case is_integer(key) do
      true -> [decode(val)]
      false -> %{key => decode(val)}
    end
  end

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