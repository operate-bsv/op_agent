defmodule Operate.VM.Extension.BaseTest do
  use ExUnit.Case
  alias Operate.VM
  doctest Operate.VM.Extension.Base

  setup_all do
    %{ vm: VM.init }
  end

  describe "Operate.VM.Extension.Base.encode16/1 and Operate.VM.Extension.Base.decode16/1" do
    test "must encode binary string as hex string", ctx do
      assert VM.eval!(ctx.vm, "return base.encode16('foo bar')") == "666f6f20626172"
    end

    test "must decode hex string as binary string", ctx do
      assert VM.eval!(ctx.vm, "return base.decode16('666f6f20626172')") == "foo bar"
      # With mixed casings
      assert VM.eval!(ctx.vm, "return base.decode16('666F6F20626172')") == "foo bar"
      assert VM.eval!(ctx.vm, "return base.decode16('666F6f20626172')") == "foo bar"
    end
  end


  describe "Operate.VM.Extension.Base.encode64/1 and Operate.VM.Extension.Base.decode64/1" do
    test "must encode binary string as hex string", ctx do
      assert VM.eval!(ctx.vm, "return base.encode64('foo bar')") == "Zm9vIGJhcg=="
    end

    test "must decode hex string as binary string", ctx do
      assert VM.eval!(ctx.vm, "return base.decode64('Zm9vIGJhcg==')") == "foo bar"
    end
  end

end