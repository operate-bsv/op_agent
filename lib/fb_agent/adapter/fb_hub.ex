defmodule FBAgent.Adapter.FBHub do
  @moduledoc """
  Adapter module for loading functions from the [Functional Bitcoin Hub](http://functions.chronoslabs.net).

  ## Examples

      iex> FBAgent.Adapter.Hub.fetch_procs(refs)
      {:ok, [%FBAgent.Function{}, ...]}

  """
  use FBAgent.Adapter
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://functions.chronoslabs.net/api/"
  plug Tesla.Middleware.JSON


  def fetch_procs(refs, options \\ []) when is_list(refs) do
    api_key = Keyword.get(options, :api_key)
    case get("/functions", query: [refs: refs, script: true], headers: [key: api_key]) do
      {:ok, res} ->
        functions = res.body["data"]
        |> Enum.map(&to_function/1)
        {:ok, functions}
      error -> error
    end
  end


  # Private: Convert an item from the http response to a `t:FBAgent.Function.t`
  defp to_function(%{} = r) do
    struct(FBAgent.Function, [
      ref: r["ref"],
      hash: r["hash"],
      name: r["name"],
      script: r["script"]
    ])
  end

end