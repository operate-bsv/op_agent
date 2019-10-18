defmodule FBAgent.Cache do
  @moduledoc """
  Functional Bitcoin cache specification.

  A cache is responsible for storing and retrieving tapes and procs from a
  cache, and if necessary instructing an adapter to fetch items from a data
  source. A cache must implement both of the following callbacks:

  * `c:fetch_tx/3` - function that takes a txid and returns a `FBAgent.BPU.Transaction.t`
  * `c:fetch_procs/3` - function that takes a list of procedure references and
  returns a list of `t:FBAgent.Function.t` functions.

  The third argument in both functions is a tuple containing the adapter module
  and a keyword list of options to pass to the adapter.

  ## Example

      defmodule MyCache do
        use FBAgent.Cache

        def fetch_tx(txid, opts, {adapter, adapter_opts}) do
          ttl = Keyword.get(opts, :ttl, 3600)
          Cache.fetch_or_store(txid, ttl: ttl, fn ->
            adapter.fetch_tx(txid, adapter_opts)
          end)
        end
      end
  """

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour FBAgent.Cache

      def fetch_tx(txid, _options \\ [], {adapter, adapter_opts}),
        do: adapter.fetch_tx(txid, adapter_opts)

      def fetch_tx!(txid, options \\ [], {adapter, adapter_opts}) do
        case fetch_tx(txid, options, {adapter, adapter_opts}) do
          {:ok, tape} -> tape
          {:error, err} -> raise err
        end
      end

      def fetch_procs(refs, _options \\ [], {adapter, adapter_opts}),
        do: adapter.fetch_procs(refs, adapter_opts)

      def fetch_procs!(refs, options \\ [], {adapter, adapter_opts}) do
        case fetch_procs(refs, options, {adapter, adapter_opts}) do
          {:ok, result} -> result
          {:error, err} -> raise err
        end
      end

      defoverridable  fetch_tx: 2, fetch_tx: 3,
                      fetch_tx!: 2, fetch_tx!: 3,
                      fetch_procs: 2, fetch_procs: 3,
                      fetch_procs!: 2, fetch_procs!: 3
    end
  end


  @doc """
  Loads a transaction from the cache by the given txid, or delegates to job to
  the passed adapter. Returns the result in an `:ok/:error` tuple pair.
  """
  @callback fetch_tx(String.t, keyword, {module, keyword}) ::
    {:ok, FBAgent.Tape.t} |
    {:error, String.t}


  @doc """
  As `c:fetch_tx/3`, but returns the transaction or raises an exception.
  """
  @callback fetch_tx!(String.t, keyword, {module, keyword}) :: FBAgent.Tape.t


  @doc """
  Loads functions from the cache by the given procedure referneces, or delegates
  the job to the passed adapter. Returns the result in an `:ok/:error` tuple
  pair.
  """
  @callback fetch_procs(list, keyword, {module, keyword}) ::
    {:ok, [FBAgent.Function.t, ...]} |
    {:error, String.t}


  @doc """
  As `c:fetch_procs/3`, but returns the result or raises an exception.
  """
  @callback fetch_procs!(list, keyword, {module, keyword}) ::
    [FBAgent.Function.t, ...]
  
end