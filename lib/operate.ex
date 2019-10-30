defmodule Operate do
  @moduledoc """
  Load and run Operate programs (known as "tapes") from the BSV blockchain.

  Operate is an extensible Bitcoin meta programming protocol. It offers a way of
  constructing Turing Complete programs encapsulated in Bitcoin transactions
  that can be be used to process data, perform calculations and operations, and
  return any kind of result.

  ## Installation

  The package is bundled with `libsecp256k1` NIF bindings. `libtool`, `automake`
  and `autogen` are required in order for the package to compile.

  The package can be installed by adding `operate`
  o your list of dependencies
  in `mix.exs`:

      def deps do
        [
          {:operate, "~> #{ Mix.Project.config[:version] }"}
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

  * `:tape_adpater` - The adapter module used to fetch the tape transaction.
  * `:proc_adpater` - The adapter module used to fetch the a tape's function scripts.
  * `:cache` - The cache module used for caching tapes and functions.
  * `:extensions` - A list of extension modules to extend the VM state.
  * `:aliases` - A map of references to alias functions to alternative references.
  * `:strict` - Set `false` to disable strict mode and ignore missing and/or erring functions.

  The default configuration:

      tape_adapter: Operate.Adapter.Bob,
      proc_adapter: Operate.Adapter.OpApi,
      cache: Operate.Cache.NoCache,
      extensions: [],
      aliases: %{},
      strict: true
  """
  use Agent
  alias Operate.{Tape, VM}


  @default_config %{
    tape_adapter: Operate.Adapter.Bob,
    proc_adapter: Operate.Adapter.OpApi,
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
    tape_adapter  = adapter_with_opts(config.tape_adapter)
    proc_adapter  = adapter_with_opts(config.proc_adapter)
    {cache, cache_opts} = adapter_with_opts(config.cache)

    aliases = Map.get(config, :aliases, %{})

    with {:ok, tx} <- cache.fetch_tx(txid, cache_opts, tape_adapter),
      {:ok, tape} <- Tape.from_bpu(tx),
      refs <- Tape.get_op_refs(tape, aliases),
      {:ok, procs} <- cache.fetch_ops(refs, cache_opts, proc_adapter),
      tape <- Tape.set_cell_ops(tape, procs, aliases)
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
      {:error, tape} -> raise tape.error
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


  # Private: Returns the adapter and options in a tuple pair
  defp adapter_with_opts(mod) when is_atom(mod), do: {mod, []}

  defp adapter_with_opts({mod, opts} = pair)
    when is_atom(mod) and is_list(opts),
    do: pair

end