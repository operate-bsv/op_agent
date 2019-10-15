defmodule FBAgent.VM.Extension.Context do
  @moduledoc """
  Extends the VM state with functions for accessing the transaction context.
  """
  alias FBAgent.VM

  @behaviour VM.Extension

  def extend(vm) do
    vm
    |> VM.set!("ctx", [])
    |> VM.set_function!("ctx.tx_input", fn vm, args -> apply(__MODULE__, :tx_input, [vm | args]) end)
    |> VM.set_function!("ctx.tx_output", fn vm, args -> apply(__MODULE__, :tx_output, [vm | args]) end)
    |> VM.set_function!("ctx.get_tape", fn vm, args -> apply(__MODULE__, :get_tape, [vm | args]) end)
    |> VM.set_function!("ctx.get_cell", fn vm, args -> apply(__MODULE__, :get_cell, [vm | args]) end)
  end


  @doc """
  Fetches the input from the context tx.
  """
  def tx_input(vm, index) when is_integer(index) do
    with {:ok, tx} when is_map(tx) <- VM.get(vm, "ctx.tx"),
         inputs when is_list(inputs) <- get_in(tx, ["in"])
    do
      Enum.at(inputs, index)
    else
      _err -> nil
    end
  end

  @doc """
  Fetches the output from the context tx.
  """
  def tx_output(vm, index) when is_integer(index) do
    with {:ok, tx} when is_map(tx) <- VM.get(vm, "ctx.tx"),
         outputs when is_list(outputs) <- get_in(tx, ["out"])
    do
      Enum.at(outputs, index)
    else
      _err -> nil
    end
  end

  @doc """
  Fetches the current tape from the context tx.
  """
  def get_tape(vm) do
    with {:ok, index} when is_integer(index) <- VM.get(vm, "ctx.tape_index"),
         output when is_map(output) <- tx_output(vm, index)
    do
      [_ | tape] = Enum.reduce(output["tape"], [], fn %{"cell" => cells}, data ->
        parse_cells(cells) ++ data
      end)
      tape
      |> Enum.reverse
      |> Enum.map(&encode_op_code/1)
    else
      _err -> nil
    end
  end

  @doc """
  Fetches the current tape from the context tx.
  """
  def get_cell(vm, index) when is_integer(index) do
    with {:ok, tape_index} when is_integer(tape_index) <- VM.get(vm, "ctx.tape_index"),
         output when is_map(output) <- tx_output(vm, tape_index)
    do
      Enum.at(output["tape"], index)
      |> Map.get("cell")
      |> parse_cells
      |> Enum.reverse
      |> Enum.map(&encode_op_code/1)
    else
      _err -> nil
    end
  end

  def get_cell(vm) do
    with {:ok, index} when is_integer(index) <- VM.get(vm, "ctx.local_index") do
      get_cell(vm, index)
    else
      _err -> nil
    end
  end


  # Pivate functions
  # Parses list of BPU cells into flat list of raw data
  defp parse_cells(cells, data \\ [])

  defp parse_cells([], data) do
    case :OP_RETURN in data do
      true -> data
      false -> ["|" | data]
    end
  end

  defp parse_cells([%{"op" => op} | cells], data) when is_integer(op) do
    {op_code, _} = BSV.Script.OpCode.get(op)
    parse_cells(cells, [op_code | data])
  end

  defp parse_cells([%{"b" => b} | cells], data) when is_binary(b) do
    b = Base.decode64!(b)
    parse_cells(cells, [b | data])
  end


  # Private functions
  # Encodes op code into binary
  defp encode_op_code(op) when is_atom(op) do
    {_, opcode_num} = BSV.Script.OpCode.get(op)
    <<opcode_num::integer>>
  end
  defp encode_op_code(op), do: op
end
