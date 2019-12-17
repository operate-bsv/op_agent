defmodule Operate.Adapter.Bob do
  @moduledoc """
  Adapter module for loading tapes and Ops from [BOB](https://bob.planaria.network).

  ## Examples

      iex> Operate.Adapter.Bob.fetch_tx(txid, api_key: "mykey")
      {:ok, %Operate.BPU.Transaction{}}
  """
  alias Operate.BPU

  use Operate.Adapter
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://bob.planaria.network/q/1GgmC7Cg782YtQ6R9QkM58voyWeQJmJJzG/"
  plug Tesla.Middleware.JSON

  
  def fetch_tx(txid, options \\ []) do
    api_key = Keyword.get(options, :api_key)
    path = encode_query(%{
      "v" => "3",
      "q" => %{
        "find" => %{
          "tx.h" => txid,
          "out.tape" => %{
            "$elemMatch" => %{
              "i" => 0,
              "cell.op" => 106
            }
          }
        },
        "limit" => 1
      }
    })
    case get(path, headers: [key: api_key]) do
      {:ok, res} ->
        tx = to_bpu(res.body) |> List.first
        {:ok, tx}
      error -> error
    end
  end


  @doc """
  Fetches a list of transactions by the given query map, and returns the result
  in an `:ok` / `:error` tuple pair.

  The `query` parameter should be a valid Bitquery. The `project` attribute
  cannot be used and unless otherwise specified, `limit` defaults to `10`.

  ## Options

  The accepted options are:

  * `:api_key` - Planaria API key

  ## Examples

      Operate.Adapter.Bob.fetch_tx_by(%{
        "find" => %{
          "out.tape.cell" => %{
            "$elemMatch" => %{
              "i" => 0,
              "s" => "1PuQa7K62MiKCtssSLKy1kh56WWU7MtUR5"
            }
          }
        }
      })
  """
  def fetch_tx_by(query, options \\ []) when is_map(query) do
    api_key = Keyword.get(options, :api_key)
    query = query
    |> Map.delete("project")
    |> Map.put_new("limit", 10)
    path = encode_query(%{
      "v" => "3",
      "q" => query
    })
    case get(path, headers: [key: api_key]) do
      {:ok, res} ->
        tx = to_bpu(res.body)
        {:ok, tx}
      error -> error
    end
  end


  @doc """
  Converts the map from the Planaria HTTP response to a `t:Operate.BPU.Transaction.t/0`.
  """
  @spec to_bpu(map) :: BPU.Transaction.t | [BPU.Transaction.t, ...]
  def to_bpu(%{"u" => u, "c" => c}),
    do: u ++ c |> Enum.map(&to_bpu/1)

  def to_bpu(tx) do
    txid = get_in(tx, ["tx", "h"])
    outputs = Enum.map(tx["out"], fn o ->
      case get_in(o, ["e", "a"]) do
        "false" -> put_in(o, ["e", "a"], nil)
        _ -> o
      end
    end)

    tx
    |> Map.put(:txid, txid)
    |> Map.put("out", outputs)
    |> BPU.Transaction.from_map
  end


  # Private: Encodes map into Fat URI path
  defp encode_query(query) do
    query
    |> Jason.encode!
    |> Base.encode64
  end

end