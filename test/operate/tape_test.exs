defmodule Operate.TapeTest do
  use ExUnit.Case
  alias Operate.VM
  alias Operate.Tape
  alias Operate.Cell
  alias Operate.Adapter.OpApi
  doctest Operate.Tape

  setup_all do
    op = """
    return function(ctx, y)
      x = ctx or 0
      return math.pow(x, y)
    end
    """
    %{
      vm: VM.init,
      cell: %Cell{ref: "test", params: ["2"], op: op}
    }
  end


  describe "Operate.Tape.set_cell_ops/3" do
    setup do
      #Tesla.Mock.mock fn
      #  _ -> File.read!("test/mocks/hub_fetch_procs.json") |> Jason.decode! |> Tesla.Mock.json
      #end
      tape = %Tape{cells: [
        %Cell{ref: "9ef5fd5c", params: ["foo.bar", 1, "foo.baz", 2]},
        %Cell{ref: "0ca59130", params: ["baz", "qux", 3]}
      ]}
      %{
        tape: tape,
        ops: OpApi.fetch_ops!(["9ef5fd5c", "0ca59130"])
      }
    end

    test "must return tape with function ops", ctx do
      [cell_1 | [cell_2]] = Tape.set_cell_ops(ctx.tape, ctx.ops)
      |> Map.get(:cells)
      assert String.match?(cell_1.op, ~r/return function\(state/)
      assert String.match?(cell_2.op, ~r/return function\(state/)
    end

    test "must handle cells with duplicate refs", ctx do
      tape = %Tape{cells: [
        %Cell{ref: "9ef5fd5c", params: ["foo.bar", 1, "foo.baz", 2]},
        %Cell{ref: "0ca59130", params: ["baz", "qux", 3]},
        %Cell{ref: "0ca59130", params: ["bish", "bash", "bosh"]}
      ]}
      assert Tape.valid?(tape) == false

      tape = Tape.set_cell_ops(tape, ctx.ops)
      assert Tape.valid?(tape) == true
    end
  end


  describe "Operate.Tape.run/3" do
    test "must return a tape with result", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell]}
      |> Tape.run(ctx.vm, state: 3)
      assert tape.result == 9
    end

    test "must pipe cells and return a tape with result", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell, ctx.cell, ctx.cell, ctx.cell]}
      |> Tape.run(ctx.vm, state: 3)
      assert tape.result == 43046721
    end

    test "must pipe cells and return a tape with error", ctx do
      {:error, tape} = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.run(ctx.vm, state: 3)
      assert tape.error =~ "Lua Error"
    end

    test "must skip errors when strict mode disabled", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.run(ctx.vm, state: 3, strict: false)
      assert tape.result == 81
    end
  end


  describe "Operate.Tape.run!/3" do
    test "must pipe cells and return a tape with result", ctx do
      tape = %Tape{cells: [ctx.cell, ctx.cell, ctx.cell]}
      |> Tape.run!(ctx.vm, state: 3)
      assert tape.result == 6561
    end

    test "must pipe cells and raise and exception", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
        |> Tape.run!(ctx.vm, state: 3)
      end
    end

    test "must skip errors when strict mode disabled", ctx do
      tape = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.run!(ctx.vm, state: 3, strict: false)
      assert tape.result == 81
    end
  end


  describe "Operate.Tape.valid?/1" do
    test "must be valid with all ops", ctx do
      assert %Tape{cells: [ctx.cell, ctx.cell]}
      |> Tape.valid? == true
    end

    test "wont be valid without any ops", ctx do
      assert %Tape{cells: [Map.put(ctx.cell, :op, nil), Map.put(ctx.cell, :op, nil)]}
      |> Tape.valid? == false
    end
  end

end