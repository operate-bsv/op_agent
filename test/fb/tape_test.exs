defmodule FB.TapeTest do
  use ExUnit.Case
  alias FB.VM
  alias FB.Tape
  alias FB.Cell
  doctest FB.Tape

  setup_all do
    script = """
    local m = {}
    m.main = function(ctx, y)
      x = ctx or 0
      return math.pow(x, y)
    end
    m.mul = function(ctx, y)
      x = ctx or 0
      return x * y
    end
    return m
    """
    %{
      vm: VM.init,
      cell: %Cell{ref: "test", script: script, params: ["2"]}
    }
  end


  describe "FB.Tape.run/2" do
    test "must return a tape with result", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell]}
      |> Tape.load!
      |> Tape.run(context: 3)
      assert tape.result == 9
    end

    test "must pipe cells and return a tape with result", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell, ctx.cell, ctx.cell, ctx.cell]}
      |> Tape.load!
      |> Tape.run(context: 3)
      assert tape.result == 43046721
    end

    test "must pipe cells and return a tape with error", ctx do
      {:error, tape} = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.load!
      |> Tape.run(context: 3)
      assert tape.error =~ "Lua Error"
    end

    test "must skip errors when strict mode disabled", ctx do
      {:ok, tape} = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.load!
      |> Tape.run(context: 3, strict: false)
      assert tape.result == 81
    end
  end


  describe "FB.Tape.run!/2" do
    test "must pipe cells and return a tape with result", ctx do
      tape = %Tape{cells: [ctx.cell, ctx.cell, ctx.cell]}
      |> Tape.load!
      |> Tape.run!(context: 3)
      assert tape.result == 6561
    end

    test "must pipe cells and raise and exception", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
        |> Tape.load!
        |> Tape.run!(context: 3)
      end
    end

    test "must skip errors when strict mode disabled", ctx do
      tape = %Tape{cells: [ctx.cell, Map.put(ctx.cell, :params, ["err"]), ctx.cell]}
      |> Tape.load!
      |> Tape.run!(context: 3, strict: false)
      assert tape.result == 81
    end
  end


  describe "FB.Tape.exec/3" do
    test "must execute secondary function using tape response", ctx do
      tape = %Tape{cells: [ctx.cell, ctx.cell]}
      |> Tape.load!
      |> Tape.run!(context: 4)
      assert tape.result == 256
      {:ok, res} = Tape.exec(tape, "test.mul", [tape.result, 4])
      assert res == 1024
    end

    test "must execute secondary function where module name begins with number", ctx do
      tape = %Tape{cells: [
        ctx.cell,
        %Cell{ref: "1abc", script: ctx.cell.script, params: ["2"]}
      ]}
      |> Tape.load!
      |> Tape.run!(context: 4)
      assert tape.result == 256
      {:ok, res} = Tape.exec(tape, "1abc.mul", [tape.result, 8])
      assert res == 2048
    end
  end

end