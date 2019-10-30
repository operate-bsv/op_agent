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
            File.read!("test/mocks/agent_exec_fetch_tx.json") |> Jason.decode! |> Tesla.Mock.json
          String.match?(env.url, ~r/functions.chronoslabs.net/) ->
            File.read!("test/mocks/agent_exec_fetch_procs.json") |> Jason.decode! |> Tesla.Mock.json
        end
      end
      :ok
    end

    test "must play and return value of given tape", ctx do
      res = VM.eval!(ctx.vm, "return agent.exec('c081e7158d76b6962ecbd3b51182aac249615743574464aa3b96fce4a998858d')")
      assert Map.keys(res) == ["name", "numbers"]
    end

    test "must build on the given state", ctx do
      res = VM.eval!(ctx.vm, "return agent.exec('c081e7158d76b6962ecbd3b51182aac249615743574464aa3b96fce4a998858d', {'testing'})")
      assert List.first(res["numbers"]) == "testing"
    end
  end

end