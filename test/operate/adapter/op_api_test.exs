defmodule Operate.Adapter.OpApiTest do
  use ExUnit.Case
  alias Operate.Adapter.OpApi

  setup do
    #Tesla.Mock.mock fn
    #  _ -> File.read!("test/mocks/hub_fetch_procs.json") |> Jason.decode! |> Tesla.Mock.json
    #end
    :ok
  end

  describe "Operate.Adapter.OpApi.fetch_ops/2 with list of references" do
    test "must return list of functions" do
      {:ok, functions} = OpApi.fetch_ops(["0b9574b5", "77bbf52e"])
      assert is_list(functions)
      assert Enum.any?(functions, &(&1.ref == "0b9574b5"))
      assert Enum.any?(functions, &(&1.ref == "77bbf52e"))
    end
  end

end