defmodule FBAgent do
  @moduledoc """
  Documentation for FBAgent.
  """
  use Agent
  alias FBAgent.VM
  alias FBAgent.Tape

  @config %{
    tape_adapter: FBAgent.Adapter.Bob,
    proc_adapter: FBAgent.Adapter.FBHub,
    extensions: [],
    aliases: %{},
    strict: true
  }

  
  @doc """
  TODOC
  """
  def start_link(options \\ []) do
    config = Enum.into(options, @config)
    vm     = VM.init(extensions: config.extensions)
    Agent.start_link(fn -> {vm, config} end, name: __MODULE__)
  end

  
  @doc """
  TODOC
  """
  def state do
    Agent.get(__MODULE__, & &1)
  end


  @doc """
  TODOC
  """
  def load_tape(txid, options \\ []) do
    {_vm, config} = state()
    {tape_adapter, tape_adpt_opts} = adapter_with_options(config.tape_adapter)
    {proc_adapter, proc_adpt_opts} = adapter_with_options(config.proc_adapter)

    aliases = config.aliases
    |> Map.merge(Keyword.get(options, :aliases, %{}))
    proc_adpt_opts = proc_adpt_opts
    |> Keyword.put(:aliases, aliases)

    with {:ok, tape} <- apply(tape_adapter, :get_tape, [txid, tape_adpt_opts]),
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
    {vm, config} = state()
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
