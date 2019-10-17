defmodule FBAgent.Cache.ConCache do
  @moduledoc """
  TODOC
  """

  def fetch_tx({adapter, adapter_opts}, txid, _options \\ []) do
    key = "t:#{ txid }"
    ConCache.fetch_or_store(:fb_agent, key, fn ->
      adapter.fetch_tx(txid, adapter_opts)
    end)
  end


  def fetch_procs({adapter, adapter_opts}, refs, _options \\ []) do
    cached_procs = refs
    |> Enum.map(&get_proc/1)
    |> Enum.into(%{})

    uncached_refs = refs
    |> Enum.reject(& &1 in Map.keys(cached_procs))

    adapter.fetch_procs(uncached_refs, adapter_opts)
    |> Enum.each(fn {ref, script} -> ConCache.put(:fb_agent, ref, script) end)
  end

  #
  #
  defp get_proc(ref) do
    key = "f:#{ ref }"
    case ConCache.get(:fb_agent, key) do
      nil -> nil
      res -> {ref, res}
    end
  end
  
end