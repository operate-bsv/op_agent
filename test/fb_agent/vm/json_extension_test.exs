defmodule FBAgent.VM.JsonExtensionTest do
  use ExUnit.Case
  alias FBAgent.VM
  doctest FBAgent.VM.JsonExtension

  setup_all do
    %{ vm: FBAgent.VM.init }
  end

  describe "FBAgent.VM.JsonExtension.encode/1" do
    test "must encode values as JSON strings", ctx do
      assert VM.eval!(ctx.vm, "return json.encode('foo bar')") == ~s("foo bar")
      assert VM.eval!(ctx.vm, "return json.encode(123)") == ~s(123)
      assert VM.eval!(ctx.vm, "return json.encode({'foo', 'bar'})") == ~s(["foo","bar"])
      assert VM.eval!(ctx.vm, "return json.encode({foo = 'bar'})") == ~s({"foo":"bar"})
      assert VM.eval!(ctx.vm, "return json.encode({foo = 'bar', 'baz'})") == ~s({"1":"baz","foo":"bar"})
    end
  end

  describe "FBAgent.VM.JsonExtension.decode/1" do
    test "must decode JSON strings as Lua types", ctx do
      assert VM.eval!(ctx.vm, "return json.decode('#{ ~s("foo bar") }') == 'foo bar'") == true
      assert VM.eval!(ctx.vm, "return json.decode('#{ ~s(123) }') == 123") == true
      assert VM.eval!(ctx.vm, "tab = json.decode('#{ ~s(["foo","bar"]) }'); return tab[1] == 'foo' and tab[2] == 'bar'") == true
      assert VM.eval!(ctx.vm, "tab = json.decode('#{ ~s({"foo":"bar"}) }'); return tab.foo == 'bar'") == true
      assert VM.eval!(ctx.vm, "tab = json.decode('#{ ~s({"1":"baz","foo":"bar"}) }'); return tab['1'] == 'baz'") == true
    end
  end

end