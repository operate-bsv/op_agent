defmodule Operate.AdapterTest do
  use ExUnit.Case
  doctest Operate.Adapter

  describe "Operate.Adapter.fetch_tx/2" do
    test "must return a result" do
      {:ok, res} = TestAdapter.fetch_tx("abc")
      assert res.__struct__ == Operate.BPU.Transaction
    end
  end


  describe "Operate.Adapter.fetch_tx!/2" do
    test "must return a result" do
      res = TestAdapter.fetch_tx!("abc")
      assert res.__struct__ == Operate.BPU.Transaction
    end

    test "must raise an exacption" do
      assert_raise RuntimeError, ~r/Test error/, fn ->
        TestAdapter.fetch_tx!(nil)
      end
    end
  end


  describe "Operate.Adapter.fetch_tx_by/2" do
    test "must return a result" do
      {:ok, res} = TestAdapter.fetch_tx_by(%{"find" => "foo"})
      assert is_list(res)
      assert res |> List.first |> Map.get(:__struct__) == Operate.BPU.Transaction
    end
  end

  describe "Operate.Adapter.fetch_tx_by!/2" do
    test "must return a result" do
      res = TestAdapter.fetch_tx_by!(%{"find" => "foo"})
      assert is_list(res)
      assert res |> List.first |> Map.get(:__struct__) == Operate.BPU.Transaction
    end
  end
end
