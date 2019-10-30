defmodule Operate.VM.Extension.StringTest do
  use ExUnit.Case
  alias Operate.VM
  doctest Operate.VM.Extension.String

  setup_all do
    %{ vm: VM.init |> Operate.VM.Extension.String.extend }
  end

  describe "Operate.VM.Extension.String.pack/2" do
    test "must pack single bytes", ctx do
      assert VM.eval!(ctx.vm, "return string.pack('<I', 5000)") == <<136, 19, 0, 0>>
      assert VM.eval!(ctx.vm, "return string.pack('<f', 5000)") == <<0, 64, 156, 69>>
      assert VM.eval!(ctx.vm, "return string.pack('<d', 5000)") == <<0, 0, 0, 0, 0, 136, 179, 64>>
      assert VM.eval!(ctx.vm, "return string.pack('>I', 5000)") == <<0, 0, 19, 136>>
      assert VM.eval!(ctx.vm, "return string.pack('>f', 5000)") == <<69, 156, 64, 0>>
      assert VM.eval!(ctx.vm, "return string.pack('>d', 5000)") == <<64, 179, 136, 0, 0, 0, 0, 0>>
    end

    test "must pack sequences of bytes", ctx do
      assert VM.eval!(ctx.vm, "return string.pack('bbbxL', 123, 124, 125, 123456789)") == <<123, 124, 125, 0, 0, 0, 0, 0, 7, 91, 205, 21>>
    end
  end

  describe "Operate.VM.Extension.String.unpack/2" do
    test "must unpack single bytes", ctx do
      assert VM.set!(ctx.vm, "bin", <<136, 19, 0, 0>>)
      |> VM.eval!("return string.unpack('<I', bin)") == [5000, 5]
      assert VM.set!(ctx.vm, "bin", <<0, 0, 0, 0, 0, 136, 179, 64>>)
      |> VM.eval!("return string.unpack('<d', bin)") == [5000, 9]
      assert VM.set!(ctx.vm, "bin", <<69, 156, 64, 0>>)
      |> VM.eval!("return string.unpack('>f', bin)") == [5000, 5]
    end

    test "must unpack sequences of bytes", ctx do
      assert VM.set!(ctx.vm, "bin", <<123, 124, 125, 0, 0, 0, 0, 0, 7, 91, 205, 21>>)
      |> VM.eval!("return string.unpack('bbbxL', bin)") == [123, 124, 125, 123456789, 13]
    end

    test "must unpack sequence at given index", ctx do
      assert VM.set!(ctx.vm, "bin", <<1, 2, 3, 4, 0, 64, 156, 69, 0, 69, 156, 64, 0, 99, 100>>)
      |> VM.eval!("return string.unpack('b<fx>f', bin, 4)") == [4, 5000, 5000, 14]
    end
  end


end