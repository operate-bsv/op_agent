defmodule Operate.CacheTest do
  use ExUnit.Case
  doctest Operate.Cache

  describe "Operate.Cache.fetch_tx/3" do
    test "must return a result" do
      {:ok, res} = TestCache.fetch_tx("abc", {TestAdapter, []})
      assert res.__struct__ == Operate.BPU.Transaction
    end
  end

  describe "Operate.Cache.fetch_tx!/3" do
    test "must return a result" do
      res = TestCache.fetch_tx!("abc", {TestAdapter, []})
      assert res.__struct__ == Operate.BPU.Transaction
    end

    test "must raise an exacption" do
      assert_raise RuntimeError, ~r/Test error/, fn ->
        TestCache.fetch_tx!(nil, {TestAdapter, []})
      end
    end
  end
end
