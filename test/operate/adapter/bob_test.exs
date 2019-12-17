defmodule Operate.Adapter.BobTest do
  use ExUnit.Case
  alias Operate.Adapter.Bob

  describe "Operate.Adapter.Bob.fetch_tx/1" do
    setup do
      Tesla.Mock.mock fn
        _ -> File.read!("test/mocks/bob_fetch_tx.json") |> Jason.decode! |> Tesla.Mock.json
      end
      :ok
    end

    test "must fetch tx" do
      {:ok, tx} = Bob.fetch_tx("98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633", api_key: "test")
      assert tx.txid == "98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633"
      assert length(tx.in) == 1
      assert length(tx.out) == 3
      assert tx.out |> List.first |> Map.get(:tape) |> Enum.at(1) |> Map.get(:cell) |> length == 5
    end
  end


  describe "Operate.Adapter.Bob.fetch_tx_by/1" do
    setup do
      Tesla.Mock.mock fn
        _ -> File.read!("test/mocks/bob_fetch_tx_by.json") |> Jason.decode! |> Tesla.Mock.json
      end
      :ok
    end

    test "must fetch tx" do
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
      {:ok, txns} = Bob.fetch_tx_by(query, api_key: "test")
      assert length(txns) == 3
      assert Enum.map(txns, & &1.txid) == [
        "8f6628e6c942ba140e3f0b6e296df0e66a2da1f2bf6ab0671840924a6a31289f",
        "301453862873865821ac93ed67cf62f9f0c8ef1e7372ac009afb8419fad7e713",
        "b2294f24f60f3a4ec90cbce12d6b2ee3582501ab6e5ddf78b060874f3e809bc6"
      ]
    end
  end

end