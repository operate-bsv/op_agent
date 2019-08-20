defmodule FB.VMTest do
  use ExUnit.Case
  alias FB.VM
  doctest FB.VM

  setup_all do
    %{ vm: FB.VM.init }
  end


  describe "FB.VM.init/1" do
    test "must return a VM state" do
      vm = FB.VM.init
      assert is_tuple(vm)
      assert elem(vm, 0) == :luerl
    end
  end


  describe "FB.VM.eval/1" do
    test "must evaluate the script and return a value", ctx do
      res = VM.eval(ctx.vm, "return table.concat({'hello', 'world'}, ' ')")
      assert res == {:ok, "hello world"}
    end

    test "must evaluate the script and return an error message", ctx do
      res = VM.eval(ctx.vm, "return 'test' {& 'invalid'")
      assert elem(res, 0) == :error
      assert elem(res, 1) =~ "Lua Error"
    end
  end


  describe "FB.VM.eval!/1" do
    test "must evaluate the script and return a value", ctx do
      res = VM.eval!(ctx.vm, "return table.concat({'hello', 'world'}, ' ')")
      assert res == "hello world"
    end

    test "must evaluate the script and raise an exception", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        VM.eval!(ctx.vm, "return 'test' {& 'invalid'")
      end
    end
  end


  describe "FB.VM.exec/1" do
    test "must execute the script and return a value", ctx do
      res = VM.exec(ctx.vm, "function main(a, b) return table.concat({a, b}, ' ') end", ["hello", "world"])
      assert res == {:ok, "hello world"}
    end

    test "must execute the named handler function", ctx do
      res = VM.exec(ctx.vm, "function test() return 32 / 6 end", [], handler: :test)
      assert res == {:ok, 5.3333333333333333}
    end

    test "must return an error message when no script", ctx do
      res = VM.exec(ctx.vm, "function foo() 123 end", [])
      assert elem(res, 0) == :error
      assert elem(res, 1) =~ "Lua Error"
    end
  end


  describe "FB.VM.exec!/1" do
    test "must execute the script and return a value", ctx do
      res = VM.exec!(ctx.vm, "function main(a, b) return table.concat({a, b}, ' ') end", ["hello", "world"])
      assert res == "hello world"
    end

    test "must raise an error when no script", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        VM.exec!(ctx.vm, "function foo() 123 end", [])
      end
    end
  end


  describe "FB.VM.decode/1" do
    test "must decode strings", ctx do
      res = VM.eval!(ctx.vm, "return 'hello world'")
      assert res == "hello world"
    end

    test "must decode numbers as floats", ctx do
      res = VM.eval!(ctx.vm, "return 2.2")
      assert res == 2.2
    end

    test "must decode numbers as integers", ctx do
      res = VM.eval!(ctx.vm, "return 2")
      assert res == 2
    end

    test "must decode flat table as list", ctx do
      res = VM.eval!(ctx.vm, "return {'foo', 'bar'}")
      assert res == ["foo", "bar"]
    end

    test "must decode flat table containing nested tables as list", ctx do
      res = VM.eval!(ctx.vm, "return {'foo', 'bar', {'a', 'b'}, {baz = 'qux'}}")
      assert res == ["foo", "bar", ["a", "b"], %{"baz" => "qux"}]
    end
    
    test "must decode associative table as map", ctx do
      res = VM.eval!(ctx.vm, "return {foo={bar=1, baz=2}}")
      assert res == %{"foo" => %{"bar" => 1, "baz" => 2}}
    end

    test "must decode complex associative table as map", ctx do
      res = VM.eval!(ctx.vm, "return {a=1, b='foo', c={n=1.2, m={'a', 'b', c={1,2,3}}}}")
      assert res == %{"a" => 1, "b" => "foo", "c" => %{"n" => 1.2, "m" => %{1 => "a", 2 => "b", "c" => [1,2,3]}}}
    end

    test "must decode multiple values as a list", ctx do
      res = VM.eval!(ctx.vm, "return 'foo', 'bar'")
      assert res == ["foo", "bar"]
    end

    test "must decode multiple mixed values as a list", ctx do
      res = VM.eval!(ctx.vm, "return 'foo', { foo = 'bar', qux = { 1,2,3 } }")
      assert res == ["foo", %{"foo" => "bar", "qux" => [1,2,3]}]
    end
  end

end