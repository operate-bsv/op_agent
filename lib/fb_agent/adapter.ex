defmodule FBAgent.Adapter do
  @moduledoc """
  Functional Bitcoin adapter specification.

  An adapter is responsible for loading tapes and procs from a datasource -
  potentially a web API, a datebase or even a Bitcoin node. Functional Bitcoin
  comes bundled with two default adapters, although these can be swapped out
  with any other adpater by changing the configuration:

      children = [
        {FBAgent, [
          tape_adapter: FBAgent.Adapter.Bob,
          proc_adapter: FBAgent.Adapter.FBHub
        ]}
      ]
      Supervisor.start_link(children, strategy: :one_for_one)

  ## Creating an adapter

  An adapter must implement one or both of the following callbacks:

  * `c:fetch_tx/2` - function that takes a txid and returns a `t:FBAgent.BPU.Transaction.t`
  * `c:fetch_procs/2` - function that takes a list of procedure references and
  returns a list of `t:FBAgent.Function.t` functions.

  Example:

      defmodule MyAdapter do
        use FBAgent.Adapter

        def fetch_tx(txid, opts) do
          key = Keyword.get(opts, :api_key)
          BitcoinApi.load_tx(txid, api_key: key)
          |> to_bpu
        end

        defp to_bpu(tx) do
          # Map tx object to `FBAgent.BPU.Transaction.t`
        end
      end

  Using the above example, Functional Bitcoin can be configured with:

      {FBAgent, [
        tape_adapter: {MyAdapter, [api_key: "myapikey"]}
      ]}
  """

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour FBAgent.Adapter

      def fetch_tx(_txid, _options \\ []),
        do: raise "#{__MODULE__}.fetch_tx/3 not implemented"

      def fetch_tx!(txid, options \\ []) do
        case fetch_tx(txid, options) do
          {:ok, tape} -> tape
          {:error, err} -> raise err
        end
      end

      def fetch_procs(_refs, _options \\ []),
        do: raise "#{__MODULE__}.fetch_procs/3 not implemented"

      def fetch_procs!(refs, options \\ []) do
        case fetch_procs(refs, options) do
          {:ok, result} -> result
          {:error, err} -> raise err
        end
      end

      defoverridable  fetch_tx: 1, fetch_tx: 2,
                      fetch_tx!: 1, fetch_tx!: 2,
                      fetch_procs: 1, fetch_procs: 2,
                      fetch_procs!: 1, fetch_procs!: 2
    end
  end


  @doc """
  Fetches a transaction by the given txid, and returns the result in an
  `:ok/:error` tuple pair.
  """
  @callback fetch_tx(String.t, keyword) ::
    {:ok, FBAgent.Tape.t} |
    {:error, String.t}


  @doc """
  As `c:fetch_tx/2`, but returns the transaction or raises an exception.
  """
  @callback fetch_tx!(String.t, keyword) :: FBAgent.Tape.t


  @doc """
  Fetches a list of functions by the given list of references. Returns
  the result in an `:ok/:error` tuple pair.
  """
  @callback fetch_procs(list, keyword) ::
    {:ok, [FBAgent.Function.t, ...]} |
    {:error, String.t}


  @doc """
  As `c:fetch_procs/2`, but returns the result or raises an exception.
  """
  @callback fetch_procs!(list, keyword) :: [FBAgent.Function.t, ...]

end