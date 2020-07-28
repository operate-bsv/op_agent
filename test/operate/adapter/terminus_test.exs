defmodule Operate.Adapter.TerminusTest do
  use ExUnit.Case
  alias Operate.Adapter.Terminus

  @host "http://localhost:8088"
  @token "test"


  describe "Operate.Adapter.Terminus.fetch_tx/1" do
    test "must fetch tx" do
      {:ok, tx} = Terminus.fetch_tx("98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633", host: @host, token: @token)
      assert tx.txid == "98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633"
      assert length(tx.in) == 1
      assert length(tx.out) == 3
      assert tx.out |> List.first |> Map.get(:tape) |> Enum.at(1) |> Map.get(:cell) |> length == 5
    end

    #test "must return error without valid token" do
    #  {:error, err} = Terminus.fetch_tx("98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633", host: @host)
    #  assert err.status == 403
    #end
  end


  describe "Operate.Adapter.Terminus.fetch_tx_by/1" do
    setup do
      query = %{
        "find" => %{
          "out.tape.cell" => %{
            "$elemMatch" => %{
              "i" => 0,
              "s" => "1PuQa7K62MiKCtssSLKy1kh56WWU7MtUR5"
            }
          }
        },
        "limit" => 3
      }
      %{query: query}
    end

    test "must fetch tx", %{query: query} do
      {:ok, txns} = Terminus.fetch_tx_by(query, host: @host, token: @token)
      assert length(txns) == 6
      assert Enum.map(txns, & &1.txid) == [
        "a33ca626e0671c1c5b70af6ad8437383521e4e7f246ff99ccf60bb52d2d10593",
        "9d8782a37be96bf3dc0ab6ff150cd352618cab52cb504fc399598cf03a80cc68",
        "7b0332451ab74dfd428bcc3b6897ed2ea79d000e8082992ffebb8aed345205d7",
        "9f394642c5c2dfef8c65db42c45c785f4b656e14206bfa878d8a0b2dec132667",
        "df61fbcb650586167bdd4cf6807f89e716d56d116173b15c37902bbd4d28fd95",
        "2c83d5222d86c56ffe08008b642ab59389892d96afbc1dc81fd11e663811c79b"
      ]
    end
  end

end
