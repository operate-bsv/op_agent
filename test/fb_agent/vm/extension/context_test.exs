defmodule FBAgent.VM.Extension.ContextTest do
  use ExUnit.Case
  alias FBAgent.VM
  alias FBAgent.Adapter.Bob
  doctest FBAgent.VM.Extension.Context

  setup_all do
    bpu = File.read!("test/mocks/bob_fetch_tx.json")
    |> Jason.decode!
    |> Bob.to_bpu
    |> List.first
    vm = VM.init
    |> FBAgent.VM.Extension.Context.extend
    |> VM.set!("ctx.tx", bpu)
    |> VM.set!("ctx.tape_index", 0)
    |> VM.set!("ctx.local_index", 2)
    |> VM.set!("ctx.global_index", 7)
    %{
      vm: vm,
      vm2: VM.init |> FBAgent.VM.Extension.Context.extend
    }
  end


  describe "FBAgent.VM.Extension.Context.tx_input/2" do
    test "with state must return the input by index", ctx do
      res = VM.eval!(ctx.vm, "return ctx.tx_input(0)")
      assert Map.keys(res) == ["__struct__", "e", "i", "tape"]
      assert Map.keys(res["e"]) == ["a", "h", "i"]
    end

    test "out of range must return nil", ctx do
      res = VM.eval!(ctx.vm, "return ctx.tx_input(1000)")
      assert is_nil(res)
    end

    test "without state must return nil", ctx do
      res = VM.eval!(ctx.vm2, "return ctx.tx_input(1)")
      assert is_nil(res)
    end
  end


  describe "FBAgent.VM.Extension.Context.tx_output/2" do
    test "with state must return the output by index", ctx do
      res = VM.eval!(ctx.vm, "return ctx.tx_output(1)")
      assert Map.keys(res) == ["__struct__", "e", "i", "tape"]
      assert Map.keys(res["e"]) == ["a", "i", "v"]
    end

    test "out of range must return nil", ctx do
      res = VM.eval!(ctx.vm, "return ctx.tx_output(1000)")
      assert is_nil(res)
    end

    test "without state must return nil", ctx do
      res = VM.eval!(ctx.vm2, "return ctx.tx_output(1)")
      assert is_nil(res)
    end
  end


  describe "FBAgent.VM.Extension.Context.get_tape/" do
    test "with state must return the current tape", ctx do
      res = VM.eval!(ctx.vm, "return ctx.get_tape()")
      assert length(res) == 28
    end

    test "without state must return nil", ctx do
      res = VM.eval!(ctx.vm2, "return ctx.get_tape()")
      assert is_nil(res)
    end
  end


  describe "FBAgent.VM.Extension.Context.get_cell/" do
    test "without index must return the current cell", ctx do
      res = VM.eval!(ctx.vm, "return ctx.get_cell()")
      assert List.first(res) |> Map.get("v") == "1PuQa7K62MiKCtssSLKy1kh56WWU7MtUR5"
      assert length(res) == 17
    end

    test "with index must return the requested cell", ctx do
      res = VM.eval!(ctx.vm, "return ctx.get_cell(1)")
      assert List.first(res) |> Map.get("v") == "19HxigV4QyBv3tHpQVcUEQyq1pzZVdoAut"
      assert length(res) == 6
    end

    test "without state must return nil", ctx do
      res = VM.eval!(ctx.vm2, "return ctx.get_tape()")
      assert is_nil(res)
    end
  end

end