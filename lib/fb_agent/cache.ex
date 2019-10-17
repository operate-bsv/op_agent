defmodule FBAgent.Cache do
  @moduledoc """
  The Function Bitcoin cache behaviour specification,

  An cache is any module responsible for storing and retrieving tx and procs
  from a cache, and if necessary instructing an adapter to fetch items from a
  datesource.
  """

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour FBAgent.Cache

      def fetch_tx({adapter, adapter_opts}, txid, _options \\ []),
        do: adapter.fetch_tx(txid, adapter_opts)

      def fetch_tx!({adapter, adapter_opts}, txid, options \\ []) do
        case fetch_tx({adapter, adapter_opts}, txid, options) do
          {:ok, tape} -> tape
          {:error, err} -> raise err
        end
      end

      def fetch_procs({adapter, adapter_opts}, refs, _options \\ []),
        do: adapter.fetch_procs(refs, adapter_opts)

      def fetch_procs!({adapter, adapter_opts}, refs, options \\ []) do
        case fetch_procs({adapter, adapter_opts}, refs, options) do
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
  Fetches a transaction by the given txid, and returns a `FBAgent.BPU.Transaction.t`
  """
  @callback fetch_tx({module, keyword}, String.t, keyword)
    :: {:ok, FBAgent.Tape.t} | {:error, String.t}


  @doc """
  As `c:fetch_tx/2`, but returns the transaction or raises an exception.
  """
  @callback fetch_tx!({module, keyword}, String.t, keyword) :: FBAgent.Tape.t


  @doc """
  Fetches procedure scripts by the given list of references or tape, returning
  either a list of functions or a tape with cells prepared for execution.
  """
  @callback fetch_procs({module, keyword}, list, keyword)
    :: {:ok, list} | {:error, String.t}


  @doc """
  As `t:fetch_procs/2`, but returns the result or raises an exception.
  """
  @callback fetch_procs!({module, keyword}, list, keyword) :: list
  
end