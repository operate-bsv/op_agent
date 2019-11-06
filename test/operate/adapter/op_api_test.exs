defmodule Operate.Adapter.OpApiTest do
  use ExUnit.Case
  alias Operate.Adapter.OpApi

  setup do
    Tesla.Mock.mock fn
      _ -> File.read!("test/mocks/api_fetch_ops.json") |> Jason.decode! |> Tesla.Mock.json
    end
    :ok
  end

  describe "Operate.Adapter.OpApi.fetch_ops/2 with list of references" do
    test "must return list of functions" do
      {:ok, functions} = OpApi.fetch_ops(["9ef5fd5c", "0ca59130"])
      assert is_list(functions)
      assert Enum.any?(functions, &(&1.ref == "9ef5fd5c"))
      assert Enum.any?(functions, &(&1.ref == "0ca59130"))
    end
  end

end