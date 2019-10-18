defmodule FBAgent.Adapter.FBHub do
  @moduledoc """
  Adapter module for loading procedure scripts from the [Functional Bitcoin Hub](http://functions.chronoslabs.net).

  ## Examples

      FBAgent.Adapter.Bob.get_tape(txid)
      |> FBAgent.Adapter.Hub.fetch_procs
      # => {:ok, %FBAgent.Tape{}}
  """
  use FBAgent.Adapter
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://functions.chronoslabs.net/api/"
  plug Tesla.Middleware.JSON


  def fetch_procs(refs, options \\ []) when is_list(refs) do
    api_key = Keyword.get(options, :api_key)
    case get("/functions", query: [refs: refs, script: true], headers: [key: api_key]) do
      {:ok, res} ->
        procs = res.body["data"]
        {:ok, procs}
      error -> error
    end
  end

end