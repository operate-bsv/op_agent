defmodule OperateTest do
  use ExUnit.Case
  doctest Operate

  setup_all do
    {:ok, _pid} = Operate.start_link(aliases: %{
      "19HxigV4QyBv3tHpQVcUEQyq1pzZVdoAut" => "6232de04", # b
      "1PuQa7K62MiKCtssSLKy1kh56WWU7MtUR5" => "1fec30d4", # map
      "15PciHG22SNLQJXMoSUaWVi7WSqc7hCfva" => "a3a83843"  # aip
    })
    :ok
  end


  describe "Operate.load_tape/1" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/bob_fetch_tx.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/operate_load_tape_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must load and prepare valid tape" do
      {:ok, tape} = Operate.load_tape("98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633")
      assert Operate.Tape.valid?(tape)
      assert length(tape.cells) == 3
    end

    test "must load and run tape" do
      {:ok, tape} = Operate.load_tape!("98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633")
      |> Operate.run_tape
      assert tape.result["app"] == "twetch"
      assert tape.result |> Map.has_key?("_MAP")
      assert tape.result |> Map.has_key?("_AIP")
    end
  end


  describe "Operate.load_tape/1 using txid with output index" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/operate_load_tape_indexed.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/agent_local_tape_load_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must load and run correct tape" do
      {:ok, tape1} = Operate.load_tape!("abcdef/1")
      |> Operate.run_tape
      {:ok, tape2} = Operate.load_tape!("abcdef/2")
      |> Operate.run_tape

      assert tape1.result == %{"baz" => "qux"}
      assert tape2.result == %{"quux" => "garply"}
    end
  end


  describe "Operate.load_tapes_by/1" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/bob_fetch_tx_by.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/operate_load_tape_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
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

    test "must load and prepare valid tapes", ctx do
      {:ok, tapes} = Operate.load_tapes_by(ctx.query)
      assert length(tapes) == 3
      assert tapes |> Enum.all?(& Operate.Tape.valid?(&1))
      assert tapes |> List.first |> Map.get(:cells) |> length == 1
      assert tapes |> List.last |> Map.get(:cells) |> length == 3
    end

    test "must run all tapes", ctx do
      tapes = Operate.load_tapes_by!(ctx.query)
      |> Enum.map(& Operate.run_tape!(&1))
      assert length(tapes) == 3
      assert tapes |> Enum.all?(& !is_nil(&1.result))
    end
  end

end
