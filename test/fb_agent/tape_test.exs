defmodule FBAgent.TapeTest do
  use ExUnit.Case
  alias FBAgent.VM
  alias FBAgent.Tape
  alias FBAgent.Cell
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


  describe "FBAgent.Tape.run/3" do
    test "must return a tape with result", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell]}
      |> Tape.run(ctx.vm, context: 3)
      assert tape.result == 9
    end

    test "must pipe cells and return a tape with result", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell, ctx.cell, ctx.cell, ctx.cell]}
      |> Tape.run(ctx.vm, context: 3)
      assert tape.result == 43046721
    end

    test "must pipe cells and return a tape with error", ctx do
      {:error, tape} = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.run(ctx.vm, context: 3)
      assert tape.error =~ "Lua Error"
    end

    test "must skip errors when strict mode disabled", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.run(ctx.vm, context: 3, strict: false)
      assert tape.result == 81
    end
  end


  describe "FBAgent.Tape.run!/3" do
    test "must pipe cells and return a tape with result", ctx do
      tape = %Tape{cells: [ctx.cell, ctx.cell, ctx.cell]}
      |> Tape.run!(ctx.vm, context: 3)
      assert tape.result == 6561
    end

    test "must pipe cells and raise and exception", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
        |> Tape.run!(ctx.vm, context: 3)
      end
    end

    test "must skip errors when strict mode disabled", ctx do
      tape = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.run!(ctx.vm, context: 3, strict: false)
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