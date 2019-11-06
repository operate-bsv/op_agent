defmodule Operate.VM.Extension.AgentTest do
  use ExUnit.Case
  alias Operate.VM
  doctest Operate.VM.Extension.Agent

  setup_all do
    %{ vm: VM.init |> Operate.VM.Extension.Agent.extend }
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

end