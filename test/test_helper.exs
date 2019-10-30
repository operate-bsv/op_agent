ExUnit.start()


defmodule TestAdapter do
  use Operate.Adapter
  def fetch_tx(txid, _opts \\ []) do
    case txid do
      nil -> {:error, "Test error"}
      _ -> {:ok, %Operate.BPU.Transaction{}}
    end
  end
end


defmodule TestCache do
  use Operate.Cache
  def fetch_tx(txid, _opts \\ [], {adapter, adapter_opts}),
    do: adapter.fetch_tx(txid, adapter_opts)
end
