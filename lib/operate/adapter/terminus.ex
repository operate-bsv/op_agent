defmodule Operate.Adapter.Terminus do
  @moduledoc """
  Adapter module for loading tapes from [Bitbus](https://bitbus.network/) and
  [Bitsocket](https://bitbus.network/) using Terminus.

  ## Examples

      iex> Operate.Adapter.Terminus.fetch_tx(txid, token: "mytoken")
      {:ok, %Operate.BPU.Transaction{}}
  """
  alias Operate.BPU
  use Operate.Adapter


  def fetch_tx(txid, options \\ []) do
    host = Keyword.get(options, :host, :bob)
    token = Keyword.get(options, :token)
    use_bitfs = Keyword.get(options, :use_bitfs, true)

    case Terminus.Omni.find(txid, host: host, token: token) do
      {:ok, tx} ->
        tx = tx
        |> fetch_bitfs_data(use_bitfs)
        |> to_bpu
        {:ok, tx}

      error ->
        error
    end
  end


  def fetch_tx_by(query, options \\ []) when is_map(query) do
    host = Keyword.get(options, :host, :bob)
    token = Keyword.get(options, :token)
    use_bitfs = Keyword.get(options, :use_bitfs, true)

    case Terminus.Omni.fetch(query, host: host, token: token) do
      {:ok, %{:u => u, :c => c}} ->
        txns = u ++ c
        |> Enum.map(& fetch_bitfs_data(&1, use_bitfs))
        |> Enum.map(&to_bpu/1)
        {:ok, txns}

      error ->
        error
    end
  end


  @doc """
  Converts the map from the Planaria HTTP response to a `t:Operate.BPU.Transaction.t/0`.
  """
  @spec to_bpu(map) :: BPU.Transaction.t | [BPU.Transaction.t, ...]
  def to_bpu(nil), do: nil

  def to_bpu(tx) do
    txid = get_in(tx, ["tx", "h"])
    outputs = Enum.map(tx["out"], fn o ->
      case get_in(o, ["e", "a"]) do
        "false" -> put_in(o, ["e", "a"], nil)
        _ -> o
      end
    end)

    tx
    |> Map.put(:txid, txid)
    |> Map.put("out", outputs)
    |> BPU.Transaction.from_map
  end


  # TODO
  defp fetch_bitfs_data(%{} = tx, false), do: tx
  defp fetch_bitfs_data(%{} = tx, true), do: Terminus.BitFS.scan_tx(tx)

end
