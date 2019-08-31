defmodule FB.Adapter.Bob do
  @moduledoc """
  Adapter module for loading tapes and procedure scripts from [BOB](https://bob.planaria.network).

  ## Examples

      FB.Adapter.Bob.get_tape(txid)
      # => %FB.Tape{}
  """
  alias FB.Tape
  alias FB.Cell
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://bob.planaria.network/q/1GgmC7Cg782YtQ6R9QkM58voyWeQJmJJzG/"
  plug Tesla.Middleware.JSON

  @behaviour FB.Adapter


  @doc """
  Fetches a transaction by the given txid, and maps it into a tape.
  """
  @impl FB.Adapter
  @spec get_tape(String.t, keyword) :: Tape.t
  def get_tape(txid, options \\ []) do
    api_key = Keyword.get(options, :api_key)
    path = FB.Util.encode_query(%{
      "v" => "3",
      "q" => %{
        "find" => %{
          "tx.h" => txid,
          "out.tape.cell" => %{
            "$elemMatch" => %{
              "ii" => 0,
              "op" => 106
            }
          }
        },
        "limit" => 1
      }
    })
    case get(path, headers: [key: api_key]) do
      {:ok, res}  -> (res.body["u"] ++ res.body["c"]) |> List.first |> to_tape
      res         -> res
    end
  end
  

  defp to_tape(tx) do
    out = Enum.find(tx["out"], &op_return_output?/1)
    cells = out["tape"]
    |> Enum.reject(&op_return_cell?/1)
    |> Enum.map(&to_cell/1)
    %Tape{ tx: tx, cells: cells }
  end


  defp to_cell(%{"cell" => [head | tail]}) do
    ref = case String.length(head["h"] || "") do
      64  -> head["h"]
      _   -> head["s"]
    end
    params = Enum.map(tail, &(&1["ls"] || &1["s"]))
    %Cell{ref: ref, params: params}
  end


  defp op_return_output?(out) do
    is_map(out) && out["tape"] |> List.first |> op_return_cell?
  end
  

  defp op_return_cell?(%{"cell" => cell}) do
    Enum.any?(cell, &(&1["op"] == 106))
  end

end