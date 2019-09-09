defmodule FBAgent do
  @moduledoc """
  Documentation for FBAgent.
  """
  alias FBAgent.Tape
  
  @doc """
  TODOC
  """
  def start_link(options \\ []) do
    cache_ttl = Keyword.get(options, :cache_ttl, FBAgent.Config.cache_ttl)

    children = [
      {FBAgent.Config, options},
      {ConCache, [
        name: :fb_agent,
        ttl_check_interval: :timer.minutes(1),
        global_ttl: cache_ttl,
        touch_on_read: true
      ]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end


  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end


  @doc """
  TODOC
  """
  def load_tape(txid, options \\ []) do
    {_vm, config} = FBAgent.Config.get
    {tape_adapter, tape_adpt_opts} = adapter_with_options(config.tape_adapter)
    {proc_adapter, proc_adpt_opts} = adapter_with_options(config.proc_adapter)

    cache = Keyword.get(options, :cache, config.cache)
    get_tape_fn = if cache, do: :cache_get_tape, else: :get_tape

    aliases = config.aliases
    |> Map.merge(Keyword.get(options, :aliases, %{}))

    proc_adpt_opts = proc_adpt_opts
    |> Keyword.put(:aliases, aliases)

    with {:ok, tape} <- apply(tape_adapter, get_tape_fn, [txid, tape_adpt_opts]),
         {:ok, tape} <- apply(proc_adapter, :get_procs, [tape, proc_adpt_opts])
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
    {vm, config} = FBAgent.Config.get
    vm = Keyword.get(options, :vm, vm)
    context = Keyword.get(options, :context, nil)
    exec_opts = [context: context, strict: config.strict]

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


  defp adapter_with_options(adapter) do
    case adapter do
      {adapter, opts} -> {adapter, opts}
      adapter -> {adapter, []}
    end
  end

end