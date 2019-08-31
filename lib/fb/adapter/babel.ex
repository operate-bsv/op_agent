defmodule FB.Adapter.Babel do
  @moduledoc """
  Adapter module for loading tapes and procedure scripts from [Babel](https://babel.bitdb.network).

  ## Examples

      FB.Adapter.Babel.get_tape(txid)
      # => %FB.Tape{}
  """
  alias FB.Tape
  alias FB.Cell
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://babel.bitdb.network/q/1DHDifPvtPgKFPZMRSxmVHhiPvFmxZwbfh/"
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
          "$or" => [
            %{ "out.b0.op" => 106 },
            %{ "out.b1.op" => 106 },
          ]  
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
    out = Enum.find(tx["out"], &op_return?/1)
    cells = Map.keys(out)
    |> Stream.filter(&(String.match?(&1, ~r/\d+$/)))
    |> Stream.map(&(String.replace(&1, ~r/^[^\d]+/, "")))
    |> Stream.uniq
    |> Enum.sort(&(String.to_integer(&1) < String.to_integer(&2)))
    |> Stream.map(&(%{
      b: out["b" <> &1] || out["lb" <> &1],
      h: out["h" <> &1] || out["lh" <> &1],
      s: out["s" <> &1] || out["ls" <> &1]
    }))
    |> Enum.reduce([%Cell{}], &to_cell/2)
    |> Enum.reverse
    %Tape{ cells: cells }
  end


  defp to_cell(%{b: %{"op" => _}}, [cell]), do: [cell]

  defp to_cell(d, [cell | tape]) when cell == %Cell{} do
    ref = case String.length(d.h || "") do
      64  -> d.h
      _   -> d.s
    end
    [%Cell{ ref: ref } | tape]
  end

  defp to_cell(%{s: "|"}, tape) do
    [%Cell{} | tape]
  end

  defp to_cell(d, [cell | tape]) do
    cell = Map.put(cell, :params, cell.params ++ [d.s])
    [cell | tape]
  end
  

  defp op_return?(out) do
    is_map(out) && (
      out["b0"]["op"] == 106 || out["b1"]["op"] == 106
    )
  end
  
end