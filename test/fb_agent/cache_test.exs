defmodule FBAgent.CacheTest do
  use ExUnit.Case
  doctest FBAgent.Cache

  describe "FBAgent.Cache.fetch_tx/3" do
    test "must return a result" do
      {:ok, res} = TestCache.fetch_tx("abc", {TestAdapter, []})
      assert res.__struct__ == FBAgent.BPU.Transaction
    end
  end

  describe "FBAgent.Cache.fetch_tx!/3" do
    test "must return a result" do
      res = TestCache.fetch_tx!("abc", {TestAdapter, []})
      assert res.__struct__ == FBAgent.BPU.Transaction
    end

    test "must raise an exacption" do
      assert_raise RuntimeError, ~r/Test error/, fn ->
        TestCache.fetch_tx!(nil, {TestAdapter, []})
      end
    end
  end
end
