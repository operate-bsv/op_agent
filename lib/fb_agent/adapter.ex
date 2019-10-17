defmodule FBAgent.Adapter do
  @moduledoc """
  The Function Bitcoin adapter specification,

  An adapter is any module responsible for loading tx and procs from a
  datasource - normally a web API or a database. The module must export:

  * `fetch_tx/2` - function that takes a txid and returns a `FBAgent.BPU.Transaction.t`
  * `fetch_procs/2` - function that takes an array of procedure references and
  returns an array of scripts.
  """

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour FBAgent.Adapter

      def fetch_tx(_txid, _options \\ []),
        do: raise "#{__MODULE__}.fetch_tx/2 not implemented"

      def fetch_tx!(txid, options \\ []) do
        case fetch_tx(txid, options) do
          {:ok, tape} -> tape
          {:error, err} -> raise err
        end
      end

      def fetch_procs(_refs, _options \\ []),
        do: raise "#{__MODULE__}.fetch_procs/2 not implemented"

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
  Fetches a transaction by the given txid, and returns a `FBAgent.BPU.Transaction.t`
  """
  @callback fetch_tx(String.t, keyword) :: {:ok, FBAgent.Tape.t} | {:error, String.t}


  @doc """
  As `c:fetch_tx/2`, but returns the transaction or raises an exception.
  """
  @callback fetch_tx!(String.t, keyword) :: FBAgent.Tape.t


  @doc """
  Fetches procedure scripts by the given list of references or tape, returning
  either a list of functions or a tape with cells prepared for execution.
  """
  @callback fetch_procs(list | FBAgent.Tape.t, keyword) :: {:ok, list | FBAgent.Tape.t} | {:error, String.t}


  @doc """
  As `t:fetch_procs/2`, but returns the result or raises an exception.
  """
  @callback fetch_procs!(list | FBAgent.Tape.t, keyword) :: list | FBAgent.Tape.t
  
end