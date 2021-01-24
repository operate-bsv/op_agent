defmodule Operate do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

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
    [txid, index] = case String.split(txid, "/") do
      [_txid, _index] = pair -> pair
      [txid] -> [txid, nil]
    end
    {_vm, config} = get_state(options)
    tape_adapter = adapter_with_opts(config.tape_adapter)
    {cache, cache_opts} = adapter_with_opts(config.cache)

    with  {:ok, tx} <- cache.fetch_tx(txid, cache_opts, tape_adapter),
          {:ok, tape} <- prep_tape(tx, index, config)
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
          {:ok, tapes} <- prep_tapes(txns, config)
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
  Prepare the tape from the given transaction. Optionally specify the output
  index of the tape.
  """
  @spec prep_tape(Transaction.t, integer | nil, map | keyword) ::
    {:ok, Tape.t} |
    {:error, String.t}
  def prep_tape(tx, index \\ nil, options \\ [])

  def prep_tape(%Transaction{} = tx, index, options) when is_list(options) do
    {_vm, config} = get_state(options)
    prep_tape(tx, index, config)
  end

  def prep_tape(%Transaction{} = tx, index, config) when is_map(config) do
    op_adapter = adapter_with_opts(config.op_adapter)
    {cache, cache_opts} = adapter_with_opts(config.cache)
    aliases = Map.get(config, :aliases, %{})

    with  {:ok, tape} <- Tape.from_bpu(tx, index),
          refs <- Tape.get_op_refs(tape, aliases),
          {:ok, ops} <- cache.fetch_ops(refs, cache_opts, op_adapter),
          tape <- Tape.set_cell_ops(tape, ops, aliases)
    do
      {:ok, tape}
    else
      error -> error
    end
  end


  @doc """
  As `prep_tape/3`, but returns the tape or raises an exception.
  """
  @spec prep_tape!(Transaction.t, integer | nil, keyword) :: Tape.t
  def prep_tape!(%Transaction{} = tx, index \\ nil, options \\ []) do
    case prep_tape(tx, index, options) do
      {:ok, tape} -> tape
      {:error, error} -> raise error
    end
  end


  @doc """
  Prepare the tapes from the given list of transactions.
  """
  @spec prep_tapes([Transaction.t, ...], map | keyword, list) ::
    {:ok, [Tape.t, ...]} |
    {:error, String.t}
  def prep_tapes(txns, config \\ [], tapes \\ [])

  def prep_tapes([], _config, tapes),
    do: {:ok, Enum.reverse(tapes)}

  def prep_tapes(txns, options, tapes) when is_list(options) do
    {_vm, config} = get_state(options)
    prep_tapes(txns, config, tapes)
  end

  def prep_tapes([%Transaction{} = tx | txns], config, tapes)
    when is_map(config)
  do
    case prep_tape(tx, nil, config) do
      {:ok, tape} -> prep_tapes(txns, config, [tape | tapes])
      error ->
        if config.strict, do: error, else: prep_tapes(txns, config, tapes)
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

  defp adapter_with_opts([mod, opts])
    when is_binary(mod) and is_list(opts),
    do: {String.to_atom("Elixir." <> mod), opts}

  defp adapter_with_opts([mod]) when is_binary(mod),
    do: {String.to_atom("Elixir." <> mod), []}

end
