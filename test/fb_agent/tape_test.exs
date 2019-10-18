defmodule FBAgent.TapeTest do
  use ExUnit.Case
  alias FBAgent.VM
  alias FBAgent.Tape
  alias FBAgent.Cell
  alias FBAgent.Adapter.FBHub
  doctest FBAgent.Tape

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


  describe "FBAgent.Tape.apply_procs/3" do
    setup do
      Tesla.Mock.mock fn
        _ -> File.read!("test/mocks/hub_fetch_procs.json") |> Jason.decode! |> Tesla.Mock.json
      end
      tape = %Tape{cells: [
        %Cell{ref: "0b9574b5", params: ["foo.bar", 1, "foo.baz", 2]},
        %Cell{ref: "77bbf52e", params: ["baz", "qux", 3]}
      ]}
      %{
        tape: tape,
        procs: FBHub.fetch_procs!(["0b9574b5", "77bbf52e"])
      }
    end

    test "must return tape with function scripts", ctx do
      [cell_1 | [cell_2]] = Tape.apply_procs(ctx.tape, ctx.procs)
      |> Map.get(:cells)
      assert String.match?(cell_1.script, ~r/return function\(state/)
      assert String.match?(cell_2.script, ~r/return function\(state/)
    end

    test "must handle cells with duplicate refs", ctx do
      tape = %Tape{cells: [
        %Cell{ref: "0b9574b5", params: ["foo.bar", 1, "foo.baz", 2]},
        %Cell{ref: "77bbf52e", params: ["baz", "qux", 3]},
        %Cell{ref: "77bbf52e", params: ["bish", "bash", "bosh"]}
      ]}
      assert Tape.valid?(tape) == false

      tape = Tape.apply_procs(tape, ctx.procs)
      assert Tape.valid?(tape) == true
    end
  end


  describe "FBAgent.Tape.run/3" do
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


  describe "FBAgent.Tape.run!/3" do
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


  describe "FBAgent.Tape.valid?/1" do
    test "must be valid with all scripts", ctx do
      assert %Tape{cells: [ctx.cell, ctx.cell]}
      |> Tape.valid? == true
    end

    test "wont be valid without any scripts", ctx do
      assert %Tape{cells: [Map.put(ctx.cell, :script, nil), Map.put(ctx.cell, :script, nil)]}
      |> Tape.valid? == false
    end
  end

end