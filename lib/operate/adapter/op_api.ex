defmodule Operate.Adapter.OpApi do
  @moduledoc """
  Adapter module for loading Ops from the [Operate API](http://api.operatebsv.org).

  ## Examples

      iex> Operate.Adapter.Hub.fetch_ops(refs)
      {:ok, [%Operate.Op{}, ...]}

  """
  use Operate.Adapter
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://api.operatebsv.org/"
  plug Tesla.Middleware.JSON


  def fetch_ops(refs, options \\ []) when is_list(refs) do
    api_key = Keyword.get(options, :api_key)
    case get("/ops", query: [refs: refs, fn: true], headers: [key: api_key]) do
      {:ok, res} ->
        ops = res.body["data"]
        |> Enum.map(&to_function/1)
        {:ok, ops}
      error -> error
    end
  end


  # Private: Convert an item from the http response to a `Operate.Op.t`
  defp to_function(%{} = r) do
    struct(Operate.Op, [
      ref: r["ref"],
      hash: r["hash"],
      name: r["name"],
      fn: r["fn"]
    ])
  end

end
