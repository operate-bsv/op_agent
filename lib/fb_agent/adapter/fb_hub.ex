defmodule FBAgent.Adapter.FBHub do
  @moduledoc """
  Adapter module for loading procedure scripts from the [Functional Bitcoin Hub](http://functions.chronoslabs.net).

  ## Examples

      FBAgent.Adapter.Bob.get_tape(txid)
      |> FBAgent.Adapter.Hub.fetch_procs
      # => {:ok, %FBAgent.Tape{}}
  """
  alias FBAgent.Tape

  use FBAgent.Adapter
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://functions.chronoslabs.net/api/"
  plug Tesla.Middleware.JSON


  def fetch_procs(refs_or_tape, options \\ [])

  def fetch_procs(refs, options) when is_list(refs) do
    api_key = Keyword.get(options, :api_key)
    case get("/functions", query: [refs: refs, script: true], headers: [key: api_key]) do
      {:ok, res} -> {:ok, res.body["data"]}
      err -> err
    end
  end

  def fetch_procs(%Tape{} = tape, options) do
    aliases = Keyword.get(options, :aliases, %{})
    refs = tape
    |> Tape.procedure_refs
    |> Enum.map(&(Map.get(aliases, &1, &1)))
    |> Enum.uniq

    case fetch_procs(refs, options) do
      {:ok, functions} ->
        {:ok, add_tape_procs(tape, functions, aliases)}
      err -> err
    end
  end


  defp add_tape_procs(tape, [func | tail], aliases) do
    ref = case Enum.find(aliases, fn {_k, v} -> v == func["ref"] end) do
      {k, _v} -> k
      _ -> func["ref"]
    end

    cells = tape.cells
    |> Enum.map(&(put_cell_script(&1, ref, func["script"])))

    Map.put(tape, :cells, cells)
    |> add_tape_procs(tail, aliases)
  end

  defp add_tape_procs(tape, [], _aliases), do: tape

  defp put_cell_script(cell, ref, script) do
    case cell.ref do
      ^ref -> Map.put(cell, :script, script)
      _ -> cell
    end
  end

end