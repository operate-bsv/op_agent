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


  describe "FB.VM.eval/2" do
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


  describe "FB.VM.eval!/2" do
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


  describe "FB.VM.call/3" do
    test "must execute the script and return a value", ctx do
      res = Sandbox.play!(ctx.vm, "function main(a, b) return table.concat({a, b}, ' ') end")
      |> VM.call(:main, ["hello", "world"])
      assert res == {:ok, "hello world"}
    end

    test "must execute the named handler function", ctx do
      res = Sandbox.play!(ctx.vm, "m = {}; function m.test() return 32 / 6 end")
      |> VM.call("m.test")
      assert res == {:ok, 5.3333333333333333}
    end

    test "must return an error message when no script", ctx do
      {:error, error} = Sandbox.play!(ctx.vm, "function foo() return 123 end")
      |> VM.call(:main)
      assert error =~ "Lua Error"
    end
  end


  describe "FB.VM.call!/3" do
    test "must execute the script and return a value", ctx do
      res = Sandbox.play!(ctx.vm, "function main(a, b) return table.concat({a, b}, ' ') end")
      |> VM.call!(:main, ["hello", "world"])
      assert res == "hello world"
    end

    test "must raise an error when no script", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        Sandbox.play!(ctx.vm, "function foo() return 123 end")
        |> VM.call!(:main)
      end
    end
  end


  describe "FB.VM.exec/2" do
    test "must call the function and return a value", ctx do
      res = VM.eval!(ctx.vm, "return function(a,b) return a * b end")
      |> VM.exec([3,5])
      assert res == {:ok, 15}
    end

    test "must be able to call nested functions in the returned result", ctx do
      script = """
      return function(a,b)
        local m = {
          a = a,
          b = b
        }
        function m.sum()
          return m.a + m.b
        end
        function m.mul()
          return m.a * m.b
        end
        return m
      end
      """
      {:ok, res} = VM.eval!(ctx.vm, script)
      |> VM.exec([3,5])

      assert res["a"] == 3
      assert res["b"] == 5
      assert VM.exec(res["sum"]) == {:ok, 8}
      assert VM.exec(res["mul"]) == {:ok, 15}
    end
  end

  describe "FB.VM.exec!/2" do
    test "must call the function and return a value", ctx do
      res = VM.eval!(ctx.vm, "return function(a,b) return a * b end")
      |> VM.exec!([3, 5])
      assert res == 15
    end

    test "must raise an error when no script", ctx do
      assert_raise RuntimeError, ~r/Lua Error/, fn ->
        VM.eval!(ctx.vm, "return function(a,b) return a * b end")
        |> VM.exec!(["hello", "world"])
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