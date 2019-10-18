defmodule FBAgent.Cache.ConCache do
  @moduledoc """
  TODOC
  """
  use FBAgent.Cache

  def fetch_tx(txid, _options \\ [], {adapter, adapter_opts}) do
    key = "t:#{ txid }"
    ConCache.fetch_or_store(:fb_agent, key, fn ->
      adapter.fetch_tx(txid, adapter_opts)
    end)
  end


  def fetch_procs(refs, _options \\ [], {adapter, adapter_opts}) do
    cached_procs = refs
    |> Enum.map(& ConCache.get(:fb_agent, &1))

    cached_refs = cached_procs
    |> Enum.map(& &1["ref"])

    uncached_refs = refs
    |> Enum.reject(& &1 in cached_refs)

    uncached_procs = case length(uncached_refs) do
      0 -> {:ok, []}
      _ -> adapter.fetch_procs(uncached_refs, adapter_opts)
    end

    with {:ok, procs} <- uncached_procs do
      Enum.each(procs, fn proc ->
        key = "p:#{ proc["ref"] }"
        ConCache.put(:fb_agent, key, proc)
      end)
      {:ok, Enum.concat(cached_procs, procs)}
    else
      error -> error
    end
  end
  
end