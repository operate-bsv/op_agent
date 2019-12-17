defmodule Operate.Adapter do
  @moduledoc """
  Operate adapter specification.

  An adapter is responsible for loading tapes and ops from a datasource -
  potentially a web API, a database or even a Bitcoin node. Operate ships with
  two default adapters, although these can be swapped out with any other adpater
  by changing the configuration:

      children = [
        {Operate, [
          tape_adapter: Operate.Adapter.Bob,
          op_adapter: Operate.Adapter.OpApi
        ]}
      ]
      Supervisor.start_link(children, strategy: :one_for_one)

  ## Creating an adapter

  An adapter must implement one or more of the following callbacks:

  * `c:fetch_tx/2` - function that takes a txid and returns a `t:Operate.BPU.Transaction.t/0`.
  * `c:fetch_tx_by/2` - function that takes a map and returns a list of `t:Operate.BPU.Transaction.t/0` tx.
  * `c:fetch_ops/2` - function that takes a list of Op references and returns a list of `t:Operate.Op.t/0` functions.

  Example:

      defmodule MyAdapter do
        use Operate.Adapter

        def fetch_tx(txid, opts) do
          key = Keyword.get(opts, :api_key)
          BitcoinApi.load_tx(txid, api_key: key)
          |> to_bpu
        end

        defp to_bpu(tx) do
          # Map tx object to `Operate.BPU.Transaction.t`
        end
      end

  Using the above example, Operate can be configured with:

      {Operate, [
        tape_adapter: {MyAdapter, [api_key: "myapikey"]}
      ]}
  """

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour Operate.Adapter

      def fetch_tx(_txid, _options \\ []),
        do: raise "#{__MODULE__}.fetch_tx/2 not implemented"

      def fetch_tx!(txid, options \\ []) do
        case fetch_tx(txid, options) do
          {:ok, tx} -> tx
          {:error, err} -> raise err
        end
      end

      def fetch_tx_by(_query, _options \\ []),
        do: raise "#{__MODULE__}.fetch_tx_by/2 not implemented"

      def fetch_tx_by!(query, options \\ []) do
        case fetch_tx_by(query, options) do
          {:ok, txns} -> txns
          {:error, err} -> raise err
        end
      end

      def fetch_ops(_refs, _options \\ []),
        do: raise "#{__MODULE__}.fetch_ops/2 not implemented"

      def fetch_ops!(refs, options \\ []) do
        case fetch_ops(refs, options) do
          {:ok, ops} -> ops
          {:error, err} -> raise err
        end
      end

      defoverridable  fetch_tx: 1, fetch_tx: 2,
                      fetch_tx!: 1, fetch_tx!: 2,
                      fetch_tx_by: 1, fetch_tx_by: 2,
                      fetch_tx_by!: 1, fetch_tx_by!: 2,
                      fetch_ops: 1, fetch_ops: 2,
                      fetch_ops!: 1, fetch_ops!: 2
    end
  end


  @doc """
  Fetches a transaction by the given txid, and returns the result in an
  `:ok` / `:error` tuple pair.
  """
  @callback fetch_tx(String.t, keyword) ::
    {:ok, Operate.Tape.t} |
    {:error, String.t}


  @doc """
  As `c:fetch_tx/2`, but returns the transaction or raises an exception.
  """
  @callback fetch_tx!(String.t, keyword) :: Operate.Tape.t


  @doc """
  Fetches a list of transactions by the given query map, and returns the result
  in an `:ok` / `:error` tuple pair.
  """
  @callback fetch_tx_by(map, keyword) ::
    {:ok, [Operate.Tape.t, ...]} |
    {:error, String.t}


  @doc """
  As `c:fetch_tx_by/2`, but returns the result or raises an exception.
  """
  @callback fetch_tx_by!(map, keyword) :: [Operate.Tape.t, ...]


  @doc """
  Fetches a list of Ops by the given list of Op references. Returns the result
  in an `:ok` / `:error` tuple pair.
  """
  @callback fetch_ops(list, keyword) ::
    {:ok, [Operate.Op.t, ...]} |
    {:error, String.t}


  @doc """
  As `c:fetch_ops/2`, but returns the result or raises an exception.
  """
  @callback fetch_ops!(list, keyword) :: [Operate.Op.t, ...]

end