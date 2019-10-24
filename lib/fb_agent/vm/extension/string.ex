defmodule FBAgent.VM.Extension.String do
  @moduledoc """
  Extends the VM state with implementations of Lua's `string.pack` and 
  `string.unpack` functions.
  """
  use FBAgent.VM.Extension
  alias FBAgent.VM
  

  def extend(vm) do
    vm
    |> VM.set_function!("string.pack", fn _vm, [fmt| args] -> apply(__MODULE__, :pack, [fmt, args]) end)
    |> VM.set_function!("string.unpack", fn _vm, args -> apply(__MODULE__, :unpack, args) end)
  end


  @doc """
  Packs the given values into a binary using the specified format.
  """
  def pack(fmt, values) when is_list(values),
    do: do_pack(fmt, values)

  @doc """
  Unpacks the given binary string into a list of values using the specified
  format. Returns a list, the final element being the index of the next unread
  byte.
  """
  def unpack(fmt, value, n \\ 1) when is_binary(value) do
    value = cond do
      n > 1 -> :binary.part(value, n-1, byte_size(value)-(n-1))
      n < 0 -> :binary.part(value, byte_size(value), n)
      n == 0 or n > byte_size(value) -> raise "Initial position #{n} out of range"
      true -> value
    end
    do_unpack(fmt, n, value)
  end


  # Private function
  # Handles packing of data using the specified options
  defp do_pack(fmt, values, result \\ <<>>)

  defp do_pack(fmt, values, result) when fmt == "" or values == [],
    do: result

  defp do_pack(fmt, values, result) when is_binary(fmt),
    do: parse_format(fmt) |> do_pack(values, result)

  defp do_pack({[:little, :integer, :signed, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::little-integer-signed-size(size)>>)
  defp do_pack({[:little, :integer, :unsigned, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::little-integer-unsigned-size(size)>>)
  defp do_pack({[:little, :float, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::little-float-size(size)>>)
  defp do_pack({[:little, :bytes, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::little-bytes-size(size)>>)
  defp do_pack({[:big, :integer, :signed, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::big-integer-signed-size(size)>>)
  defp do_pack({[:big, :integer, :unsigned, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::big-integer-unsigned-size(size)>>)
  defp do_pack({[:big, :float, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::big-float-size(size)>>)
  defp do_pack({[:big, :bytes, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::big-bytes-size(size)>>)
  defp do_pack({[:native, :integer, :signed, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::native-integer-signed-size(size)>>)
  defp do_pack({[:native, :integer, :unsigned, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::native-integer-unsigned-size(size)>>)
  defp do_pack({[:native, :float, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::native-float-size(size)>>)
  defp do_pack({[:native, :bytes, size], fmt}, [val | rest], result),
    do: do_pack(fmt, rest, result <> <<val::native-bytes-size(size)>>)
  defp do_pack({[:padding], fmt}, rest, result),
    do: do_pack(fmt, rest, result <> <<0>>)


  # Private function
  # Handles unpacking of data using the specified options
  defp do_unpack(fmt, n, value, result \\ [])

  defp do_unpack(fmt, n, value, result) when fmt == "" or value == "",
    do: [n | result] |> Enum.reverse

  defp do_unpack(fmt, n, value, result) when is_binary(fmt),
    do: parse_format(fmt) |> do_unpack(n, value, result)

  defp do_unpack({[:little, :integer, :signed, size], fmt}, n, value, result) do
    <<val::little-integer-signed-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:little, :integer, :unsigned, size], fmt}, n, value, result) do
    <<val::little-integer-unsigned-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:little, :float, size], fmt}, n, value, result) do
    <<val::little-float-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:little, :bytes, size], fmt}, n, value, result) do
    <<val::little-bytes-size(size), rest::binary>> = value
    do_unpack(fmt, n + size, rest, [val | result])
  end
  defp do_unpack({[:big, :integer, :signed, size], fmt}, n, value, result) do
    <<val::big-integer-signed-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:big, :integer, :unsigned, size], fmt}, n, value, result) do
    <<val::big-integer-unsigned-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:big, :float, size], fmt}, n, value, result) do
    <<val::big-float-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:big, :bytes, size], fmt}, n, value, result) do
    <<val::big-bytes-size(size), rest::binary>> = value
    do_unpack(fmt, n + size, rest, [val | result])
  end
  defp do_unpack({[:native, :integer, :signed, size], fmt}, n, value, result) do
    <<val::native-integer-signed-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:native, :integer, :unsigned, size], fmt}, n, value, result) do
    <<val::native-integer-unsigned-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:native, :float, size], fmt}, n, value, result) do
    <<val::native-float-size(size), rest::binary>> = value
    do_unpack(fmt, n + floor(size/8), rest, [val | result])
  end
  defp do_unpack({[:native, :bytes, size], fmt}, n, value, result) do
    <<val::native-bytes-size(size), rest::binary>> = value
    do_unpack(fmt, n + size, rest, [val | result])
  end
  defp do_unpack({[:padding], fmt}, n, value, result) do
    <<0, rest::binary>> = value
    do_unpack(fmt, n + 1, rest, result)
  end


  # Private function
  # Parses the format string to create options for packing/unpacking
  def parse_format(fmt) do
    {opts, match} = case Regex.scan(~r/^([<>=])?([bhlifdx])(\d{1,2})?/i, fmt) do
      [[m, "<", "b"]] -> {[:little, :integer, :signed, 8], m}
      [[m, "<", "B"]] -> {[:little, :integer, :unsigned, 8], m}
      [[m, "<", "h"]] -> {[:little, :integer, :signed, 16], m}
      [[m, "<", "H"]] -> {[:little, :integer, :unsigned, 16], m}
      [[m, "<", "l"]] -> {[:little, :integer, :signed, 64], m}
      [[m, "<", "L"]] -> {[:little, :integer, :unsigned, 64], m}
      [[m, "<", "i"]] -> {[:little, :integer, :signed, 32], m}
      [[m, "<", "I"]] -> {[:little, :integer, :unsigned, 32], m}
      [[m, "<", "i", b]] -> {[:little, :integer, :signed, String.to_integer(b) * 8], m}
      [[m, "<", "I", b]] -> {[:little, :integer, :unsigned, String.to_integer(b) * 8], m}
      [[m, "<", "f"]] -> {[:little, :float, 32], m}
      [[m, "<", "d"]] -> {[:little, :float, 64], m}
      [[m, "<", "c", b]] -> {[:little, :bytes, b], m}
      [[m, ">", "b"]] -> {[:big, :integer, :signed, 8], m}
      [[m, ">", "B"]] -> {[:big, :integer, :unsigned, 8], m}
      [[m, ">", "h"]] -> {[:big, :integer, :signed, 16], m}
      [[m, ">", "H"]] -> {[:big, :integer, :unsigned, 16], m}
      [[m, ">", "l"]] -> {[:big, :integer, :signed, 64], m}
      [[m, ">", "L"]] -> {[:big, :integer, :unsigned, 64], m}
      [[m, ">", "i"]] -> {[:big, :integer, :signed, 32], m}
      [[m, ">", "I"]] -> {[:big, :integer, :unsigned, 32], m}
      [[m, ">", "i", b]] -> {[:big, :integer, :signed, String.to_integer(b) * 8], m}
      [[m, ">", "I", b]] -> {[:big, :integer, :unsigned, String.to_integer(b) * 8], m}
      [[m, ">", "f"]] -> {[:big, :float, 32], m}
      [[m, ">", "d"]] -> {[:big, :float, 64], m}
      [[m, ">", "c", b]] -> {[:big, :bytes, b], m}
      [[m, "=", "b"]] -> {[:native, :integer, :signed, 8], m}
      [[m, "=", "B"]] -> {[:native, :integer, :unsigned, 8], m}
      [[m, "=", "h"]] -> {[:native, :integer, :signed, 16], m}
      [[m, "=", "H"]] -> {[:native, :integer, :unsigned, 16], m}
      [[m, "=", "l"]] -> {[:native, :integer, :signed, 64], m}
      [[m, "=", "L"]] -> {[:native, :integer, :unsigned, 64], m}
      [[m, "=", "i"]] -> {[:native, :integer, :signed, 32], m}
      [[m, "=", "I"]] -> {[:native, :integer, :unsigned, 32], m}
      [[m, "=", "i", b]] -> {[:native, :integer, :signed, String.to_integer(b) * 8], m}
      [[m, "=", "I", b]] -> {[:native, :integer, :unsigned, String.to_integer(b) * 8], m}
      [[m, "=", "f"]] -> {[:native, :float, 32], m}
      [[m, "=", "d"]] -> {[:native, :float, 64], m}
      [[m, "=", "c", b]] -> {[:native, :bytes, b], m}
      [[m, "", "b"]] -> {[:big, :integer, :signed, 8], m}
      [[m, "", "B"]] -> {[:big, :integer, :unsigned, 8], m}
      [[m, "", "h"]] -> {[:big, :integer, :signed, 16], m}
      [[m, "", "H"]] -> {[:big, :integer, :unsigned, 16], m}
      [[m, "", "l"]] -> {[:big, :integer, :signed, 64], m}
      [[m, "", "L"]] -> {[:big, :integer, :unsigned, 64], m}
      [[m, "", "i"]] -> {[:big, :integer, :signed, 32], m}
      [[m, "", "I"]] -> {[:big, :integer, :unsigned, 32], m}
      [[m, "", "i", b]] -> {[:big, :integer, :signed, String.to_integer(b) * 8], m}
      [[m, "", "I", b]] -> {[:big, :integer, :unsigned, String.to_integer(b) * 8], m}
      [[m, "", "f"]] -> {[:big, :float, 32], m}
      [[m, "", "d"]] -> {[:big, :float, 64], m}
      [[m, "", "c", b]] -> {[:big, :bytes, b], m}
      [[m, "", "x"]] -> {[:padding], m}
    end
    [_, fmt] = String.split(fmt, match, parts: 2)
    {opts, fmt}
  end
  
end