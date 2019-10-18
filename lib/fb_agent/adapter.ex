defmodule FBAgent.Adapter do
  @moduledoc """
  Functional Bitcoin adapter behaviour.

  An adapter is responsible for loading tapes and procs from a datasource -
  potentially a web API, a datebase or even a Bitcoin node. An adapter can
  implement one or both of the following callbacks:

  * `b:fetch_tx/2` - function that takes a txid and returns a `FBAgent.BPU.Transaction.t`
  * `b:fetch_procs/2` - function that takes a list of procedure references and
  returns a list of procdure scripts.

  ## Example

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
  Fetches a transaction by the given txid, and returns the result in an OK/Error
  tuple pair.
  """
  @callback fetch_tx(String.t, keyword) ::
    {:ok, FBAgent.Tape.t} |
    {:error, String.t}


  @doc """
  As `c:fetch_tx/2`, but returns the transaction or raises an exception.
  """
  @callback fetch_tx!(String.t, keyword) :: FBAgent.Tape.t


  @doc """
  Fetches a list of procedure scripts by the given list of references. Returns
  the result in an OK/Error tuple pair.
  """
  @callback fetch_procs(list, keyword) ::
    {:ok, list} |
    {:error, String.t}


  @doc """
  As `t:fetch_procs/2`, but returns the result or raises an exception.
  """
  @callback fetch_procs!(list, keyword) :: list

end