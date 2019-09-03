defmodule FB.Adapter.HubTest do
  use ExUnit.Case
  alias FB.Adapter.Hub
  doctest FB.Adapter.Hub

  setup do
    Tesla.Mock.mock fn
      _ -> File.read!("test/mocks/hub_get_procs.json") |> Jason.decode! |> Tesla.Mock.json
    end
    :ok
  end

  describe "FB.Adapter.Hub.get_procs/2 with list of references" do
    test "must return list of functions" do
      {:ok, functions} = Hub.get_procs(["0b9574b5", "77bbf52e"])
      assert is_list(functions)
      assert Enum.any?(functions, &(&1["ref"] == "0b9574b5"))
      assert Enum.any?(functions, &(&1["ref"] == "77bbf52e"))
    end
  end

  describe "FB.Adapter.Hub.get_procs/2 with tape" do
    test "must return tape with function scripts" do
      {:ok, tape} = %FB.Tape{cells: [
        %FB.Cell{ref: "0b9574b5", params: ["foo.bar", 1, "foo.baz", 2]},
        %FB.Cell{ref: "77bbf52e", params: ["baz", "qux", 3]}
      ]}
      |> Hub.get_procs
      [cell_1 | [cell_2]] = tape.cells
      assert String.match?(cell_1.script, ~r/return function\(ctx/)
      assert String.match?(cell_2.script, ~r/return function\(ctx/)
    end
  end

end