defmodule FBAgent.AdapterTest do
  use ExUnit.Case
  doctest FBAgent.Adapter

  describe "FBAgent.Adapter.fetch_tx/2" do
    test "must return a result" do
      {:ok, res} = TestAdapter.fetch_tx("abc")
      assert res.__struct__ == FBAgent.BPU.Transaction
    end
  end

  describe "FBAgent.Adapter.fetch_tx!/2" do
    test "must return a result" do
      res = TestAdapter.fetch_tx!("abc")
      assert res.__struct__ == FBAgent.BPU.Transaction
    end

    test "must raise an exacption" do
      assert_raise RuntimeError, ~r/Test error/, fn ->
        TestAdapter.fetch_tx!(nil)
      end
    end
  end
end
