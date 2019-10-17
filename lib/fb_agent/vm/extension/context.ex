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
        normalize_cells(cells) ++ data
      end)
      Enum.reverse(tape)
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
      |> normalize_cells
      |> Enum.reverse
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
  # Normalizes list of BPU cells into simplified maps
  defp normalize_cells(source, result \\ [])

  defp normalize_cells([], result) do
    case result |> Enum.any?(& get_in(&1, [:op]) == 106) do
      true -> result
      false -> [%{b: "|"} | result]
    end
  end

  defp normalize_cells([%{"op" => op} | source], result) when is_integer(op),
    do: normalize_cells(source, [%{op: op, b: <<op::integer>>} | result])

  defp normalize_cells([%{"b" => b} | source], result) when is_binary(b),
    do: normalize_cells(source, [%{b: Base.decode64!(b)} | result])

end
