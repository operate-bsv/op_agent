defmodule FBAgent.Adapter.FBHubTest do
  use ExUnit.Case
  alias FBAgent.Adapter.FBHub
  alias FBAgent.Tape
  alias FBAgent.Cell
  doctest FBAgent.Adapter.FBHub

  setup do
    Tesla.Mock.mock fn
      _ -> File.read!("test/mocks/hub_fetch_procs.json") |> Jason.decode! |> Tesla.Mock.json
    end
    :ok
  end

  describe "FBAgent.Adapter.FBHub.fetch_procs/2 with list of references" do
    test "must return list of functions" do
      {:ok, functions} = FBHub.fetch_procs(["0b9574b5", "77bbf52e"])
      assert is_list(functions)
      assert Enum.any?(functions, &(&1["ref"] == "0b9574b5"))
      assert Enum.any?(functions, &(&1["ref"] == "77bbf52e"))
    end
  end

  describe "FBAgent.Adapter.FBHub.fetch_procs/2 with tape" do
    test "must return tape with function scripts" do
      {:ok, tape} = %Tape{cells: [
        %Cell{ref: "0b9574b5", params: ["foo.bar", 1, "foo.baz", 2]},
        %Cell{ref: "77bbf52e", params: ["baz", "qux", 3]}
      ]}
      |> FBHub.fetch_procs
      [cell_1 | [cell_2]] = tape.cells
      assert String.match?(cell_1.script, ~r/return function\(state/)
      assert String.match?(cell_2.script, ~r/return function\(state/)
    end

    test "must handle cells with duplicate refs" do
      tape = %Tape{cells: [
        %Cell{ref: "0b9574b5", params: ["foo.bar", 1, "foo.baz", 2]},
        %Cell{ref: "77bbf52e", params: ["baz", "qux", 3]},
        %Cell{ref: "77bbf52e", params: ["bish", "bash", "bosh"]}
      ]}
      assert Tape.valid?(tape) == false

      {:ok, tape} = FBHub.fetch_procs(tape)
      assert Tape.valid?(tape) == true
    end
  end

end