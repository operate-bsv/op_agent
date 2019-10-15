defmodule FBAgent.Adapter.Bob do
  @moduledoc """
  Adapter module for loading tapes and procedure scripts from [BOB](https://bob.planaria.network).

  ## Examples

      FBAgent.Adapter.Bob.fetch_tx(txid)
      # => {:ok, %FBAgent.BPU.Transaction{}}
  """
  alias FBAgent.BPU
  #alias FBAgent.Tape
  #alias FBAgent.Cell

  use FBAgent.Adapter
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://bob.planaria.network/q/1GgmC7Cg782YtQ6R9QkM58voyWeQJmJJzG/"
  plug Tesla.Middleware.JSON

  
  def fetch_tx(txid, options \\ []) do
    api_key = Keyword.get(options, :api_key)
    path = FBAgent.Util.encode_query(%{
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


  def fetch_tx!(txid, options \\ []) do
    case fetch_tx(txid, options) do
      {:ok, tape} -> tape
      {:error, err} -> raise err
    end
  end


  @doc """
  TODOC
  """
  def cache_fetch_tx(txid, options \\ []) do
    key = "t:#{txid}"
    ConCache.fetch_or_store(:fb_agent, key, fn -> fetch_tx(txid, options) end)
  end


  @doc """
  TODOC
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

end