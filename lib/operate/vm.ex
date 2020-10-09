defmodule Operate.VM do
  @moduledoc """
  Operate VM module. Responsible for initalizing the VM state and evaluating and
  executing Lua code in the VM.
  """

  @typedoc "Operate VM state"
  @type t :: {:luerl, tuple}

  @typedoc "Lua table path. Either a dot-delimited string or list of strings or atoms."
  @type lua_path :: atom | String.t | list

  @typedoc "Operate return value"
  @type lua_output :: binary | number | list | map

  @extensions [
    Operate.VM.Extension.Agent,
    Operate.VM.Extension.Context,
    Operate.VM.Extension.Crypto,
    Operate.VM.Extension.Base,
    Operate.VM.Extension.JSON,
    Operate.VM.Extension.String
  ]


  @doc """
  Initliazes a new VM state.

  ## Options

  The accepted options are:

  * `:extensions` - Provide a list of modules with which to extend the VM state.

  ## Examples

      iex> vm = Operate.VM.init
      ...> elem(vm, 0) == :luerl
      true
  """
  @spec init(keyword) :: __MODULE__.t
  def init(options \\ []) do
    extensions = @extensions
    |> Enum.concat(Keyword.get(options, :extensions, []))

    :luerl_sandbox.init
    |> extend(extensions)
  end


  @doc """
  Extends the VM state with the given module or modules.

  ## Examples

      Operate.VM.extend(vm, [MyLuaExtension, OtherExtension])
  """
  @spec extend(__MODULE__.t, list | module) :: __MODULE__.t
  def extend(vm, [module | tail]) do
    vm
    |> extend(module)
    |> extend(tail)
  end

  def extend(vm, []), do: vm

  def extend(vm, module) when is_atom(module) do
    apply(module, :extend, [vm])
  end


  @doc """
  Returns the value from the specified path on the VM state.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.set!("foo.bar", 42, force: true)
      ...> |> Operate.VM.get("foo")
      {:ok, %{"bar" => 42}}

      iex> Operate.VM.init
      ...> |> Operate.VM.set!("foo.bar", 42, force: true)
      ...> |> Operate.VM.get("foo.bar")
      {:ok, 42}
  """
  @spec get(__MODULE__.t, __MODULE__.lua_path) ::
    {:ok, __MODULE__.lua_output} |
    {:error, String.t}
  def get(vm, path) when is_binary(path),
    do: get(vm, String.split(path, "."))

  def get(vm, path) when is_atom(path),
    do: get(vm, [path])

  def get(vm, path) when is_list(path) do
    try do
      {result, _vm} = :luerl.get_table(path, vm)
      {:ok, decode(result)}
    rescue
      err -> {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `get/2`, but returns the result or raises an exception.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.set!("foo.bar", 42, force: true)
      ...> |> Operate.VM.get!("foo.bar")
      42
  """
  @spec get!(__MODULE__.t, __MODULE__.lua_path) :: __MODULE__.lua_output
  def get!(vm, path) do
    case get(vm, path) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Sets the value at the specified path on the given VM state and returns a
  modified VM state.

  ## Options

  The accepted options are:

  * `:force` - Recusively set the value at a deep path that doesn't already exist.

  ## Examples

      iex> {:ok, vm} = Operate.VM.init
      ...> |> Operate.VM.set("foo.bar", 42, force: true)
      ...> elem(vm, 0)
      :luerl
  """
  @spec set(__MODULE__.t, __MODULE__.lua_path, any, keyword) ::
    {:ok, __MODULE__.t} |
    {:error, String.t}
  def set(vm, path, value, options \\ [])

  def set(vm, path, value, options) when is_binary(path),
    do: set(vm, String.split(path, "."), value, options)

  def set(vm, path, value, options) when is_atom(path),
    do: set(vm, [path], value, options)

  def set(vm, path, value, options) when is_atom(path),
    do: set(vm, [path], value, options)

  def set(vm, path, value, options) when is_list(path) do
    force = Keyword.get(options, :force, false)
    case force do
      true ->
        set_deep_tables(vm, path)
        |> set(path, value)
      _ ->
        try do
          vm = :luerl.set_table(path, value, vm)
          {:ok, vm}
        rescue
          err -> {:error, "Lua Error: #{inspect err}"}
        end
    end
  end


  @doc """
  As `set/4`, but returns the VM state or raises an exception.

  ## Options

  The accepted options are:

  * `:force` - Recusively set the value at a deep path that doesn't already exist.

  ## Examples

      iex> vm = Operate.VM.init
      ...> |> Operate.VM.set!("foo.bar", 42, force: true)
      ...> elem(vm, 0)
      :luerl
  """
  @spec set!(__MODULE__.t, __MODULE__.lua_path, any, keyword) :: __MODULE__.t
  def set!(vm, path, value, options \\ []) do
    case set(vm, path, value, options) do
      {:ok, vm} -> vm
      {:error, err} -> raise err
    end
  end


  @doc """
  Sets an Elixir function at the specified path on the given VM state and
  returns the modified VM state.

  ## Options

  The accepted options are:

  * `:force` - Recusively set the value at a deep path that doesn't already exist.
  """
  @spec set_function(__MODULE__.t, __MODULE__.lua_path, function, keyword) ::
    {:ok, __MODULE__.t} |
    {:error, String.t}
  def set_function(vm, path, callback, options \\ [])
    when is_function(callback)
  do
    func = fn args, vm ->
      case callback.(vm, args) do
        result when is_tuple(result) ->
          {Tuple.to_list(result), vm}
        result ->
          {[result], vm}
      end
    end
    set(vm, path, func, options)
  end


  @doc """
  As `set_function/4`, but returns the VM state or raises an exception.

  ## Options

  The accepted options are:

  * `:force` - Recusively set the value at a deep path that doesn't already exist.
  """
  @spec set_function!(__MODULE__.t, __MODULE__.lua_path, function, keyword) ::
    __MODULE__.t
  def set_function!(vm, path, callback, options \\ [])
    when is_function(callback)
  do
    case set_function(vm, path, callback, options) do
      {:ok, vm} -> vm
      {:error, err} -> raise err
    end
  end


  @doc """
  Evaluates the given script within the VM state and returns the result.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.eval("return 'hello world'")
      {:ok, "hello world"}

      iex> Operate.VM.init
      ...> |> Operate.VM.eval("return 2 / 3")
      {:ok, 0.6666666666666666}
  """
  @spec eval(__MODULE__.t, String.t) ::
    {:ok, __MODULE__.lua_output} |
    {:error, String.t}
  def eval(vm, code) do
    case :luerl.eval(code, vm) do
      {:ok, result} -> {:ok, decode(result)}
      {:error, err, _stack} ->
        {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `eval/2`, but returns the result or raises an exception.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.eval!("return 'hello world'")
      "hello world"
  """
  @spec eval!(__MODULE__.t, String.t) :: __MODULE__.lua_output
  def eval!(vm, code) do
    case eval(vm, code) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Evaluates the given script within the VM state and returns the modified state.
  """
  @spec exec(__MODULE__.t, String.t) ::
    {:ok, __MODULE__.t} |
    {:error, String.t}
  def exec(vm, code) do
    try do
      {_result, vm} = :luerl.do(code, vm)
      {:ok, vm}
    rescue
      err ->
        {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `exec/2`, but returns the modified state or raises an exception.
  """
  @spec exec!(__MODULE__.t, String.t) :: __MODULE__.t
  def exec!(vm, code) do
    case exec(vm, code) do
      {:ok, vm} -> vm
      {:error, err} -> raise err
    end
  end


  @doc """
  Calls a function within the VM state at the given lua path and returns the result.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.exec!("function main() return 'hello world' end")
      ...> |> Operate.VM.call(:main)
      {:ok, "hello world"}

      iex> Operate.VM.init
      ...> |> Operate.VM.exec!("function sum(a, b) return a + b end")
      ...> |> Operate.VM.call(:sum, [2, 3])
      {:ok, 5}
  """
  @spec call(__MODULE__.t, __MODULE__.lua_path, list) ::
    {:ok, __MODULE__.lua_output} |
    {:error, String.t}
  def call(vm, path, args \\ [])

  def call(vm, path, args) when is_binary(path),
    do: call(vm, String.split(path, "."), args)

  def call(vm, path, args) when is_atom(path),
    do: call(vm, [path], args)

  def call(vm, path, args) when is_list(path) do
    try do
      {result, _vm} = :luerl.call_function(path, args, vm)
      {:ok, decode(result)}
    rescue
      err ->
        {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `call/3`, but returns the result or raises an exception.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.exec!("function main() return 'hello world' end")
      ...> |> Operate.VM.call!(:main)
      "hello world"
  """
  @spec call!(__MODULE__.t, __MODULE__.lua_path, list) :: __MODULE__.lua_output
  def call!(vm, path, args \\ []) do
    case call(vm, path, args) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Executes the given function with the given arguments.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.eval!("return function(a,b) return a * b end")
      ...> |> Operate.VM.exec_function([3,4])
      {:ok, 12}
  """
  @spec exec_function(function, list) ::
    {:ok, __MODULE__.lua_output} |
    {:error, String.t}
  def exec_function(function, args \\ []) when is_function(function) do
    try do
      result = apply(function, [args])
      {:ok, decode(result)}
    rescue
      err ->
        {:error, "Lua Error: #{inspect err}"}
    end
  end


  @doc """
  As `exec_function/2`, but returns the result or raises an exception.

  ## Examples

      iex> Operate.VM.init
      ...> |> Operate.VM.eval!("return function(a,b) return a .. ' ' .. b end")
      ...> |> Operate.VM.exec_function!(["hello", "world"])
      "hello world"
  """
  @spec exec_function!(function, list) :: __MODULE__.lua_output
  def exec_function!(function, args \\ []) when is_function(function) do
    case exec_function(function, args) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  @doc """
  Decodes a value returned from the VM state into an Elixir type.

  Automatically detects when 64 bit long numbers can be converted to integers,
  and handles converting Lua tables into either Elixir lists or maps.

  ## Examples

      iex> Operate.VM.decode(23.23)
      23.23

      iex> Operate.VM.decode(23.0)
      23

      iex> Operate.VM.decode([{"foo", 1}, {"bar", 2}])
      %{"foo" => 1, "bar" => 2}
  """
  @spec decode(binary | number | list) :: __MODULE__.lua_output

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


  @doc """
  Parses the given map decoded from the VM, and recursively transforms it into
  a keyword list with atom keys.

  ## Examples

      iex> Operate.VM.parse_opts(%{"foo" => 1, "bar" => %{"baz" => 2}})
      [bar: [baz: 2], foo: 1]

      iex> [{"foo", 1}, {"bar", 2}]
      ...> |> Operate.VM.decode
      ...> |> Operate.VM.parse_opts
      [bar: 2, foo: 1]
  """
  @spec parse_opts(map) :: keyword

  def parse_opts(%{} = opts),
    do: Enum.into(opts, [], fn {k, v} -> {String.to_atom(k), parse_opts(v)} end)

  def parse_opts([head | tail]),
    do: [parse_opts(head) | parse_opts(tail)]

  def parse_opts(val), do: val


  # Private: Determines which method to use to decode the Lue table
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


  # Private: Recursively sets empty tables on the given lua path
  defp set_deep_tables(vm, path, last_path \\ nil)
  defp set_deep_tables(vm, [], _last_path), do: vm
  defp set_deep_tables(vm, [path | rest], last_path) do
    next_path = case last_path do
      nil -> path
      _ -> last_path <> "." <> path
    end

    case get(vm, next_path) do
      {:ok, nil} -> set!(vm, next_path, [])
      _ -> vm
    end
    |> set_deep_tables(rest, next_path)
  end

end
