defmodule FBAgent.CellTest do
  use ExUnit.Case
  alias FBAgent.VM
  alias FBAgent.Cell
  doctest FBAgent.Cell

  setup_all do
    script = """
    return function(ctx, y)
      x = ctx or 0
      return math.pow(x, y)
    end
    """
    %{
      vm: VM.init,
      cell: %Cell{ref: "test", params: ["2"], script: script}
    }
  end


  describe "FBAgent.Cell.exec/3" do
    test "must return a result", ctx do
      res = Cell.exec(ctx.cell, ctx.vm, state: 2)
      assert res == {:ok, 4}
    end

    test "must return an error", ctx do
      res = Cell.exec(ctx.cell, ctx.vm, state: %{foo: "bar"})
      assert elem(res, 0) == :error
      assert elem(res, 1) =~ "Lua Error"
    end
  end


  describe "FBAgent.Cell.exec!/3" do
    test "must return a result", ctx do
      res = Cell.exec!(ctx.cell, ctx.vm, state: 2)
      assert res == 4
    end

    test "must raise an exception", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        Cell.exec!(ctx.cell, ctx.vm, state: %{foo: "bar"})
      end
    end
  end


  describe "FBAgent.Cell.valid?/1" do
    test "must be valid with ref and script" do
      assert %Cell{ref: "test", script: "testing"}
      |> Cell.valid? == true
    end

    test "wont be valid without ref" do
      assert %Cell{script: "testing"}
      |> Cell.valid? == false
    end

    test "wont be valid without script" do
      assert %Cell{ref: "test"}
      |> Cell.valid? == false
    end
  end

end