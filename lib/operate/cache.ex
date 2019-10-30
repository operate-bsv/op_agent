defmodule Operate.Cache do
  @moduledoc """
  Operate cache specification.

  A cache is responsible for storing and retrieving tapes and ops from a
  cache, and if necessary instructing an adapter to fetch items from a data
  source.

  Operate comes bundled with a `ConCache` ETS cache, although by default runs
  without any caching.

  ## Creating a cache

  A cache must implement both of the following callbacks:

  * `c:fetch_tx/3` - function that takes a txid and returns a `t:Operate.BPU.Transaction.t/0`
  * `c:fetch_ops/3` - function that takes a list of Op references and returns a list of `t:Operate.Op.t/0` functions.

  The third argument in both functions is a tuple containing the adapter module
  and a keyword list of options to pass to the adapter.

      defmodule MyCache do
        use Operate.Cache

        def fetch_tx(txid, opts, {adapter, adapter_opts}) do
          ttl = Keyword.get(opts, :ttl, 3600)
          Cache.fetch_or_store(txid, ttl: ttl, fn ->
            adapter.fetch_tx(txid, adapter_opts)
          end)
        end
      end

  Using the above example, Operate can be configured with:

      {Operate, [
        cache: {MyCache, [ttl: 3600]}
      ]}
  """

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour Operate.Cache

      def fetch_tx(txid, _options \\ [], {adapter, adapter_opts}),
        do: adapter.fetch_tx(txid, adapter_opts)

      def fetch_tx!(txid, options \\ [], {adapter, adapter_opts}) do
        case fetch_tx(txid, options, {adapter, adapter_opts}) do
          {:ok, tape} -> tape
          {:error, err} -> raise err
        end
      end

      def fetch_ops(refs, _options \\ [], {adapter, adapter_opts}),
        do: adapter.fetch_ops(refs, adapter_opts)

      def fetch_ops!(refs, options \\ [], {adapter, adapter_opts}) do
        case fetch_ops(refs, options, {adapter, adapter_opts}) do
          {:ok, result} -> result
          {:error, err} -> raise err
        end
      end

      defoverridable  fetch_tx: 2, fetch_tx: 3,
                      fetch_tx!: 2, fetch_tx!: 3,
                      fetch_ops: 2, fetch_ops: 3,
                      fetch_ops!: 2, fetch_ops!: 3
    end
  end


  @doc """
  Loads a transaction from the cache by the given txid, or delegates to job to
  the specified adapter. Returns the result in an `:ok` / `:error` tuple pair.
  """
  @callback fetch_tx(String.t, keyword, {module, keyword}) ::
    {:ok, Operate.Tape.t} |
    {:error, String.t}


  @doc """
  As `c:fetch_tx/3`, but returns the transaction or raises an exception.
  """
  @callback fetch_tx!(String.t, keyword, {module, keyword}) :: Operate.Tape.t


  @doc """
  Loads Ops from the cache by the given procedure referneces, or delegates
  the job to the specified adapter. Returns the result in an `:ok` / `:error`
  tuple pair.
  """
  @callback fetch_ops(list, keyword, {module, keyword}) ::
    {:ok, [Operate.Op.t, ...]} |
    {:error, String.t}


  @doc """
  As `c:fetch_ops/3`, but returns the result or raises an exception.
  """
  @callback fetch_ops!(list, keyword, {module, keyword}) ::
    [Operate.Op.t, ...]
  
end