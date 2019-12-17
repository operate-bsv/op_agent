defmodule Operate.TapeTest do
  use ExUnit.Case
  alias Operate.VM
  alias Operate.Tape
  alias Operate.Cell
  alias Operate.Op
  alias Operate.Adapter.OpApi
  alias Operate.BPU
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


  describe "Operate.Tape.from_bpu/2" do
    setup do
      # Fake BPU tx with OP_RETURN output 
      tx1 = %BPU.Transaction{out: [
        %BPU.Script{i: 0, tape: [
          %BPU.Cell{i: 0, cell: [
            %{i: 0, ii: 0, b: "MDAwMDAwMDAwMDAwMDAwMA==", s: "0000000000000000"},
            %{i: 1, ii: 1, op: 117, ops: "OP_DROP"}
          ]}
        ]},
        %BPU.Script{i: 1, tape: [
          %BPU.Cell{i: 0, cell: [
            %{i: 0, ii: 0, op: 0, ops: "OP_FALSE"},
            %{i: 1, ii: 1, op: 106, ops: "OP_RETURN"}
          ]},
          %BPU.Cell{i: 0, cell: [
            %{i: 0, ii: 2, b: "Zm9v", s: "foo"},
            %{i: 1, ii: 3, b: "YmFy", s: "bar"}
          ]}
        ]}
      ]}
      # Fake BPU tx with no OP_RETURN output
      tx2 = %BPU.Transaction{out: [
        %BPU.Script{i: 0, tape: [
          %BPU.Cell{i: 0, cell: [
            %{i: 0, ii: 0, b: "MDAwMDAwMDAwMDAwMDAwMA==", s: "0000000000000000"},
            %{i: 1, ii: 1, op: 117, ops: "OP_DROP"}
          ]}
        ]},
        %BPU.Script{i: 0, tape: [
          %BPU.Cell{i: 0, cell: [
            %{i: 0, ii: 0, b: "MDAwMDAwMDAwMDAwMDAwMA==", s: "0000000000000000"},
            %{i: 1, ii: 1, op: 117, ops: "OP_DROP"}
          ]}
        ]}
      ]}
      %{
        tx1: tx1,
        tx2: tx2
      }
    end

    test "must return tape from given tx output", ctx do
      {:ok, tape} = Tape.from_bpu(ctx.tx1, 1)
      assert length(tape.cells) == 1
    end

    test "must return error if given tx output is not op return", ctx do
      {:error, msg} = Tape.from_bpu(ctx.tx1, 0)
      assert msg == "No tape found in transaction."
    end

    test "must return error if given tx output does not exist", ctx do
      {:error, msg} = Tape.from_bpu(ctx.tx1, 3)
      assert msg == "No tape found in transaction."
    end

    test "must default to first op_return output", ctx do
      {:ok, tape} = Tape.from_bpu(ctx.tx1)
      assert length(tape.cells) == 1
    end

    test "must return error if no op_return output", ctx do
      {:error, msg} = Tape.from_bpu(ctx.tx2)
      assert msg == "No tape found in transaction."
    end
  end


  describe "Operate.Tape.set_cell_ops/3" do
    setup do
      Tesla.Mock.mock fn
        _ -> File.read!("test/mocks/api_fetch_ops.json") |> Jason.decode! |> Tesla.Mock.json
      end
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

    test "must handle aliases references" do
      tape = %Tape{cells: [
        %Cell{ref: "a"},
        %Cell{ref: "b"},
        %Cell{ref: "c"}
      ]}
      ops = [
        %Op{ref: "foo", fn: "return 1"},
        %Op{ref: "bar", fn: "return 2"}
      ]
      aliases = %{"a" => "foo", "b" => "bar", "c" => "bar"}
      tape = Tape.set_cell_ops(tape, ops, aliases)

      assert Tape.valid?(tape) == true
      assert tape.cells |> Enum.map(& &1.op) == ["return 1",  "return 2",  "return 2"]
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