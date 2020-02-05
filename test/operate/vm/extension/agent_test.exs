defmodule Operate.VM.Extension.AgentTest do
  use ExUnit.Case
  alias Operate.VM
  doctest Operate.VM.Extension.Agent

  setup_all do
    {:ok, _pid} = Operate.start_link(aliases: %{
      "19HxigV4QyBv3tHpQVcUEQyq1pzZVdoAut" => "6232de04", # b
      "1PuQa7K62MiKCtssSLKy1kh56WWU7MtUR5" => "1fec30d4", # map
      "15PciHG22SNLQJXMoSUaWVi7WSqc7hCfva" => "a3a83843"  # aip
    })
    %{ vm: VM.init }
  end


  describe "Operate.VM.Extension.Agent.exec/2" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/agent_exec_get_tape.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/agent_exec_get_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must play and return value of given tape", ctx do
      res = VM.eval!(ctx.vm, "return agent.exec('65aa086b2c54d5d792973db425b70712a708a115cd71fb67bd780e8ad9513ac9')")
      assert Map.keys(res) == ["name", "numbers"]
    end

    test "must build on the given state", ctx do
      res = VM.eval!(ctx.vm, "return agent.exec('65aa086b2c54d5d792973db425b70712a708a115cd71fb67bd780e8ad9513ac9', {'testing'})")
      assert List.first(res["numbers"]) == "testing"
    end
  end


  describe "Operate.VM.Extension.Agent.load_tape/2 and Operate.VM.Extension.Agent.run_tape/2" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/agent_exec_get_tape.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/agent_exec_get_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must load and run and return value of given tape", ctx do
      script = """
      local tape = agent.load_tape('65aa086b2c54d5d792973db425b70712a708a115cd71fb67bd780e8ad9513ac9')
      return agent.run_tape(tape)
      """
      res = VM.eval!(ctx.vm, script)
      assert Map.keys(res) == ["name", "numbers"]
    end

    test "must build on the given state", ctx do
      script = """
      local tape = agent.load_tape('65aa086b2c54d5d792973db425b70712a708a115cd71fb67bd780e8ad9513ac9')
      return agent.run_tape(tape, {state = {'testing'}})
      """
      res = VM.eval!(ctx.vm, script)
      assert List.first(res["numbers"]) == "testing"
    end
  end


  describe "Operate.VM.Extension.Agent.load_tapes_by/2" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/bob.planaria.network/) ->
            File.read!("test/mocks/bob_fetch_tx_by.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/operate_load_tape_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must load and run tapes from a given query", ctx do
      script = """
      local query = { find = {}, limit = 3 }
      query.find['out.tape.cell'] = {}
      query.find['out.tape.cell']['$elemMatch'] = {
        i = 0,
        s = '1PuQa7K62MiKCtssSLKy1kh56WWU7MtUR5'
      }
      local opts = {
        tape_adapter = {
          'Operate.Adapter.Bob',
          {api_key = 'foo'}
        }
      }
      local tapes = agent.load_tapes_by(query, opts)
      local results = {}
      for i, tape in ipairs(tapes) do
        local res = agent.run_tape(tape)
        table.insert(results, res)
      end
      return results
      """
      res = VM.eval!(ctx.vm, script)
      assert Enum.map(res, & &1["app"]) == ["tonicpow", "twetch", "twetch"]
    end 
  end


  describe "Operate.VM.Extension.Agent.local_tape/2" do
    setup do
      Tesla.Mock.mock fn env ->
        cond do
          String.match?(env.url, ~r/api.operatebsv.org/) ->
            File.read!("test/mocks/agent_local_tape_load_ops.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end

      script = """
      return function(state)
        local t1 = agent.local_tape(1)
        local t2 = agent.local_tape(2)
        return {
          foo = agent.run_tape(t1),
          bar = agent.run_tape(t2)
        }
      end
      """

      tape = File.read!("test/mocks/operate_load_tape_indexed.json")
      |> Jason.decode!
      |> Map.get("u")
      |> List.first
      |> Operate.BPU.Transaction.from_map
      |> Operate.prep_tape!(0)

      tape = Map.put(tape, :cells, [
        %Operate.Cell{ref: "test", op: script, index: 0, data_index: 1}
      ])
      %{
        tape: tape
      }
    end

    test "must get and run tapes from local context", ctx do
      {:ok, tape} = Operate.run_tape(ctx.tape)

      assert tape.result["foo"] == %{"baz" => "qux"}
      assert tape.result["bar"] == %{"quux" => "garply"}
    end
  end

end