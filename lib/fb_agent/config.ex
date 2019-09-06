defmodule FBAgent.Config do
  @moduledoc """
  Documentation for FBAgent.
  """
  use Agent

  @defaults %{
    tape_adapter: FBAgent.Adapter.Bob,
    proc_adapter: FBAgent.Adapter.FBHub,
    extensions: [],
    aliases: %{},
    cache: true,
    cache_ttl: :timer.minutes(10),
    strict: true
  }


  @doc """
  TODOC
  """
  def start_link(options \\ []) do
    conf  = Enum.into(options, @defaults)
    vm    = FBAgent.VM.init(extensions: conf.extensions)
    Agent.start_link(fn -> {vm, conf} end, name: __MODULE__)
  end


  @doc """
  TODOC
  """
  def get do
    Agent.get(__MODULE__, & &1)
  end

  @doc """
  TODOC
  """
  def cache_ttl, do: @defaults.cache_ttl
  
end