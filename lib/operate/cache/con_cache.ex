defmodule Operate.Cache.ConCache do
  @moduledoc """
  Cache module implementing an ETS based cache, using [ConCache](https://github.com/sasa1977/con_cache).

  To enable this cache, ConCache needs to be started from a supervisor:

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
  """
  use Operate.Cache


  def fetch_tx(txid, _options \\ [], {adapter, adapter_opts}) do
    key = "t:#{ txid }"
    ConCache.fetch_or_store(:operate, key, fn ->
      adapter.fetch_tx(txid, adapter_opts)
    end)
  end


  def fetch_tx_by(query, _options \\ [], {adapter, adapter_opts})
    when is_map(query)
  do
    hash = query
    |> Jason.encode!
    |> BSV.Crypto.Hash.sha256
    key = "t:#{ hash }"
    ConCache.fetch_or_store(:operate, key, fn ->
      adapter.fetch_tx_by(query, adapter_opts)
    end)
  end


  def fetch_ops(refs, _options \\ [], {adapter, adapter_opts}) do
    cached_ops = refs
    |> Enum.map(& ConCache.get(:operate, &1))

    cached_refs = cached_ops
    |> Enum.map(& &1["ref"])

    uncached_refs = refs
    |> Enum.reject(& &1 in cached_refs)

    uncached_ops = case length(uncached_refs) do
      0 -> {:ok, []}
      _ -> adapter.fetch_ops(uncached_refs, adapter_opts)
    end

    with {:ok, ops} <- uncached_ops do
      Enum.each(ops, fn op ->
        key = "p:#{ op["ref"] }"
        ConCache.put(:operate, key, op)
      end)
      {:ok, Enum.concat(cached_ops, ops)}
    else
      error -> error
    end
  end
  
end