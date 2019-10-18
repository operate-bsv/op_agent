defmodule FBAgent do
  @moduledoc """
  Documentation for FBAgent.

  ## Supervision

      children = [
        {FBAgent, [
          cache: FBAgent.Cache.ConCache,
        ]},
        {ConCache, [
          name: :fb_agent,
          ttl_check_interval: :timer.minutes(1),
          global_ttl: :timer.minutes(10),
          touch_on_read: true
        ]}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)
  """
  use Agent
  alias FBAgent.Adapter
  alias FBAgent.Tape


  @default_config %{
    tape_adapter: FBAgent.Adapter.Bob,
    proc_adapter: FBAgent.Adapter.FBHub,
    cache: FBAgent.Cache.NoCache,
    extensions: [],
    aliases: %{},
    strict: true
  }


  @doc """
  TODOC
  """
  def start_link(options \\ []) do
    name = Keyword.get(options, :name, __MODULE__)
    config = Enum.into(options, @default_config)
    vm = FBAgent.VM.init(extensions: config.extensions)
    Agent.start_link(fn -> {vm, config} end, name: name)
  end


  @doc """
  TODOC
  """
  def get_state(options \\ []) do
    name = Keyword.get(options, :name, __MODULE__)
    case Process.whereis(name) do
      p when is_pid(p) ->
        Agent.get(name, fn {vm, config} ->
          {Keyword.get(options, :vm, vm), Enum.into(options, config)}
        end)
      nil ->
        config = Enum.into(options, @default_config)
        vm = FBAgent.VM.init(extensions: config.extensions)
        {vm, config}
    end
  end


  @doc """
  TODOC
  """
  def load_tape(txid, options \\ []) do
    {_vm, config} = get_state(options)
    tape_adapter  = Adapter.with_options(config.tape_adapter)
    proc_adapter  = Adapter.with_options(config.proc_adapter)
    {cache, cache_opts} = Adapter.with_options(config.cache)

    aliases = Map.get(config, :aliases, %{})

    with {:ok, tx} <- cache.fetch_tx(txid, cache_opts, tape_adapter),
      tape <- Tape.from_bpu(tx),
      refs <- Tape.procedure_refs(tape)
              |> Enum.map(& Map.get(aliases, &1, &1))
              |> Enum.uniq,
      {:ok, procs} <- cache.fetch_procs(refs, cache_opts, proc_adapter),
      tape <- Tape.apply_procs(tape, procs, aliases)
    do
      {:ok, tape}
    else
      error -> error
    end
  end


  @doc """
  TODOC
  """
  def load_tape!(txid, options \\ []) do
    case load_tape(txid, options) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end


  @doc """
  TODOC
  """
  def run_tape(tape, options \\ []) do
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
  TODOC
  """
  def run_tape!(tape, options \\ []) do
    case run_tape(tape, options) do
      {:ok, tape} -> tape
      {:error, tape} -> raise tape.error
    end
  end

end