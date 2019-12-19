defmodule Operate do
  @moduledoc """
  Load and run Operate programs (known as "tapes") encoded in Bitcoin SV
  transactions.

  Operate is a toolset to help developers build applications, games and services
  on top of Bitcoin (SV). It lets you write functions, called "Ops", and enables
  transactions to become small but powerful programs, capable of delivering new
  classes of services layered over Bitcoin.

  ## Installation

  The package is bundled with `libsecp256k1` NIF bindings. `libtool`, `automake`
  and `autogen` are required in order for the package to compile.

  The package can be installed by adding `operate` to your list of dependencies
  in `mix.exs`.

  **The most recent `luerl` package published on `hex.pm` is based on Lua 5.2
  which may not be compatible with all Ops. It is recommended to override the
  `luerl` dependency with the latest development version to benefit from Lua 5.3.**

      def deps do
        [
          {:operate, "~> #{ Mix.Project.config[:version] }"},
          {:luerl, github: "rvirding/luerl", branch: "develop", override: true}
        ]
      end

  ## Quick start

  The agent can be used straight away without starting any processes. This will
  run without caching so should only be used for testing and kicking the tyres.

      {:ok, tape} = Operate.load_tape(txid)
      {:ok, tape} = Operate.run_tape(tape)

      tape.result

  See `load_tape/2` and `run_tape/2`.

  ## Process supervision

  To enable caching the agent should be started as part of your applications
  process supervision tree.

      children = [
        {Operate, [
          cache: Operate.Cache.ConCache,
        ]},
        {ConCache, [
          name: :operate,
          ttl_check_interval: :timer.minutes(1),
          global_ttl: :timer.minutes(10),
          touch_on_read: true
        ]}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)

  ## Configuration

  Operate can be configured with the following options. Additionally, any of
  these options can be passed to `load_tape/2` and `run_tape/2` to override
  the configuration.

  * `:tape_adapter` - The adapter module used to fetch the tape transaction.
  * `:op_adaapter` - The adapter module used to fetch the tape's Ops.
  * `:cache` - The cache module used for caching tapes and Ops.
  * `:extensions` - A list of extension modules to extend the VM state.
  * `:aliases` - A map of references to alias functions to alternative references.
  * `:strict` - Set `false` to disable strict mode and ignore missing and/or erring functions.

  The default configuration:

      tape_adapter: Operate.Adapter.Bob,
      op_adapter: Operate.Adapter.OpApi,
      cache: Operate.Cache.NoCache,
      extensions: [],
      aliases: %{},
      strict: true
  """
  use Agent
  alias Operate.BPU.Transaction
  alias Operate.{Tape, VM}


  @default_config %{
    tape_adapter: Operate.Adapter.Bob,
    op_adapter: Operate.Adapter.OpApi,
    cache: Operate.Cache.NoCache,
    extensions: [],
    aliases: %{},
    strict: true
  }

  @version Mix.Project.config[:version]


  @doc """
  Starts an Operate agent process with the given options merged with the default
  config.

  ## Options

  Refer to the list of accepted [configuration options](#module-configuration).
  """
  @spec start_link(keyword) :: {:ok, pid}
  def start_link(options \\ []) do
    name = Keyword.get(options, :name, __MODULE__)
    config = Enum.into(options, @default_config)
    vm = VM.init(extensions: config.extensions)
    Agent.start_link(fn -> {vm, config} end, name: name)
  end


  @doc """
  Gets Operate's current VM state and config.

  If a process has already been started then the existing VM and config
  is returned. Alternatively a new VM state is initiated and the default config
  returned. In either case any configuration option can be overridden.

  Returns a tuple pair containing the VM state and a configuration map.
  """
  @spec get_state(keyword) :: {VM.t, map}
  def get_state(options \\ []) do
    name = Keyword.get(options, :name, __MODULE__)
    case Process.whereis(name) do
      p when is_pid(p) ->
        Agent.get(name, fn {vm, config} ->
          config = Enum.into(options, config)
          vm = Keyword.get(options, :vm, vm)
          |> VM.extend(config.extensions)
          {vm, config}
        end)
      nil ->
        config = Enum.into(options, @default_config)
        vm = VM.init(extensions: config.extensions)
        {vm, config}
    end
  end


  @doc """
  Loads a tape from the given txid.

  Fetchs the tape transaction output as well as all of the required functions,
  and returns a `t:Operate.Tape.t/0` ready for execution in an `:ok` / `:error`
  tuple pair.

  If an Operate agent process has already been started the existing config will
  be used. Otherwise a default config will be used. Any configuration option can
  be overridden.

  ## Options

  Refer to the list of accepted [configuration options](#module-configuration).
  """
  @spec load_tape(String.t, keyword) :: {:ok, Tape.t} | {:error, String.t}
  def load_tape(txid, options \\ []) do
    {_vm, config} = get_state(options)
    tape_adapter = adapter_with_opts(config.tape_adapter)
    {cache, cache_opts} = adapter_with_opts(config.cache)

    with  {:ok, tx} <- cache.fetch_tx(txid, cache_opts, tape_adapter),
          {:ok, tape} <- prep_tape(tx, config)
    do
      {:ok, tape}
    else
      error -> error
    end
  end


  @doc """
  As `load_tape/2`, but returns the tape or raises an exception.
  """
  @spec load_tape!(String.t, keyword) :: Tape.t
  def load_tape!(txid, options \\ []) do
    case load_tape(txid, options) do
      {:ok, tape} -> tape
      {:error, error} -> raise error
    end
  end


  @doc """
  Loads a tape from the given query.

  The expected format of the query will depend on the `Operate.Adapter` in use.
  The transactions as well as all required functions are loaded an a list of
  `t:Operate.Tape.t/0` are returned in an `:ok` / `:error` tuple pair.

  If an Operate agent process has already been started the existing config will
  be used. Otherwise a default config will be used. Any configuration option can
  be overridden.

  ## Options

  Refer to the list of accepted [configuration options](#module-configuration).

  ## Examples

  For example, if using the default `Operate.Adapter.Bob` adapter, a Bitquery
  can be provided. The `project` attribute cannot be used and unless otherwise
  specified, `limit` defaults to `10`.

      Operate.load_tapes_by(%{
        "find" => %{
          "out.tape.cell" => %{
            "$elemMatch" => %{
              "i" => 0,
              "s" => "1PuQa7K62MiKCtssSLKy1kh56WWU7MtUR5"
            }
          }
        }
      })
  """
  @spec load_tapes_by(map, keyword) :: {:ok, [Tape.t, ...]} | {:error, String.t}
  def load_tapes_by(query, options \\ []) when is_map(query) do
    {_vm, config} = get_state(options)
    tape_adapter = adapter_with_opts(config.tape_adapter)
    {cache, cache_opts} = adapter_with_opts(config.cache)

    with  {:ok, txns} <- cache.fetch_tx_by(query, cache_opts, tape_adapter),
          {:ok, tapes} <- prep_tape(txns, config)
    do
      {:ok, tapes}
    else
      error -> error
    end
  end


  @doc """
  As `load_tapes_by/2`, but returns the tapes or raises an exception.
  """
  @spec load_tapes_by!(map, keyword) :: [Tape.t, ...]
  def load_tapes_by!(query, options \\ []) do
    case load_tapes_by(query, options) do
      {:ok, tapes} -> tapes
      {:error, error} -> raise error
    end
  end


  @doc """
  Runs the given tape executing each of the tape's cells and returns the
  modified and complete `t:Operate.Tape.t/0` in an `:ok` / `:error` tuple pair.

  If an Operate agent process has already been started the existing VM state and
  config will be used. Otherwise a new state and default config will be used.
  Any configuration option can be overridden.

  ## Options

  The accepted options are:

  * `:extensions` - A list of extension modules to extend the VM state.
  * `:strict` - Strict mode (defaults `true`). Disable to force the tape to ignore missing and/or erroring cells.
  * `:state` - Speficy a state which the tape begins execution with (defaults to `nil`).
  * `:vm` - Pass an already initiated VM state in which to run the tape.
  """
  @spec run_tape(Tape.t, keyword) :: {:ok, Tape.t} | {:error, Tape.t}
  def run_tape(%Tape{} = tape, options \\ []) do
    {vm, config} = get_state(options)
    state = Map.get(config, :state, nil)
    exec_opts = [state: state, strict: config.strict]

    with {:ok, tape} <- Tape.run(tape, vm, exec_opts) do
      {:ok, tape}
    else
      error -> error
    end
  end


  @doc """
  As `run_tape/2`, but returns the tape or raises an exception.
  """
  @spec run_tape!(Tape.t, keyword) :: Tape.t
  def run_tape!(%Tape{} = tape, options \\ []) do
    case run_tape(tape, options) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  Returns the current version number.
  """
  @spec version() :: String.t
  def version, do: @version


  # Private: prepares the tape or tapes
  defp prep_tape(txns, tapes \\ [], config)

  defp prep_tape(%Transaction{} = tx, tapes, config) do
    case prep_tape([tx], tapes, config) do
      {:ok, [tape]} -> {:ok, tape}
      error -> error
    end
  end

  defp prep_tape([], tapes, _config),
    do: {:ok, Enum.reverse(tapes)}

  defp prep_tape([%Transaction{} = tx | txns], tapes, config)
    when is_list(tapes)
  do
    op_adapter = adapter_with_opts(config.op_adapter)
    {cache, cache_opts} = adapter_with_opts(config.cache)
    aliases = Map.get(config, :aliases, %{})

    with  {:ok, tape} <- Tape.from_bpu(tx),
          refs <- Tape.get_op_refs(tape, aliases),
          {:ok, ops} <- cache.fetch_ops(refs, cache_opts, op_adapter),
          tape <- Tape.set_cell_ops(tape, ops, aliases)
    do
      prep_tape(txns, [tape | tapes], config)
    else
      error ->
        if config.strict, do: error, else: prep_tape(txns, tapes, config)
    end
  end


  # Private: Returns the adapter and options in a tuple pair
  defp adapter_with_opts(mod) when is_atom(mod), do: {mod, []}

  defp adapter_with_opts({mod, opts} = pair)
    when is_atom(mod) and is_list(opts),
    do: pair

  defp adapter_with_opts([mod, opts])
    when is_binary(mod) and is_list(opts),
    do: {String.to_atom("Elixir." <> mod), opts}

end