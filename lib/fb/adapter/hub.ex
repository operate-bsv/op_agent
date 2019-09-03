defmodule FB.Adapter.Hub do
  @moduledoc """
  Adapter module for loading procedure scripts from the [Functional Bitcoin Hub](http://functions.chronoslabs.net).

  ## Examples

      FB.Adapter.Bob.get_tape(txid)
      |> FB.Adapter.Hub.get_procs
      # => {:ok, %FB.Tape{}}
  """
  alias FB.Tape
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "http://functions.chronoslabs.net/api/"
  plug Tesla.Middleware.JSON

  @behaviour FB.Adapter


  @doc """
  Not implemented.
  """
  @impl FB.Adapter
  @spec get_tape(String.t, keyword) :: Tape.t
  def get_tape(_txid, _options \\ []), do: raise "FB.Adapter.Hub.get_tape/2 not implemented"


  @doc """
  Not implemented.
  """
  @impl FB.Adapter
  @spec get_tape!(String.t, keyword) :: Tape.t
  def get_tape!(_txid, _options \\ []), do: raise "FB.Adapter.Hub.get_tape!/2 not implemented"


  @doc """
  Fetches procedure scripts by the given list of references or tape, returning
  either a list of functions or a tape with cells prepared for execution.
  """
  @impl FB.Adapter
  @spec get_procs(list | Tape.t, keyword) :: {:ok, list | Tape.t} | {:error, String.t}
  def get_procs(refs_or_tape, options \\ [])

  def get_procs(refs, options) when is_list(refs) do
    api_key = Keyword.get(options, :api_key)
    case get("/functions", query: [refs: refs, script: true], headers: [key: api_key]) do
      {:ok, res} -> {:ok, res.body["data"]}
      err -> err
    end
  end

  def get_procs(%Tape{} = tape, options) do
    case get_procs(Tape.procedure_refs(tape), options) do
      {:ok, functions} ->
        {:ok, add_tape_procs(tape, functions)}
      err -> err
    end
  end


  @doc """
  As `f:FB.Adapter.Hub.get_procs/2`, but returns the result or raises an exception.
  """
  @impl FB.Adapter
  @spec get_procs!(list | Tape.t, keyword) :: list | Tape.t
  def get_procs!(refs_or_tape, options \\ []) do
    case get_procs(refs_or_tape, options) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end


  defp add_tape_procs(tape, [func | tail]) do
    with i when is_number(i) <- Enum.find_index(tape.cells, &(&1.ref == func["ref"])),
         cell <- Enum.at(tape.cells, i) |> Map.put(:script, func["script"]),
         cells <- List.replace_at(tape.cells, i, cell)
    do
      Map.put(tape, :cells, cells)
      |> add_tape_procs(tail)
    else
      _err -> add_tape_procs(tape, tail) 
    end
  end

  defp add_tape_procs(tape, []), do: tape

end