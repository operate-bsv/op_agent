ExUnit.start()


defmodule TestAdapter do
  use FBAgent.Adapter
  def fetch_tx(txid, _opts \\ []) do
    case txid do
      nil -> {:error, "Test error"}
      _ -> {:ok, %FBAgent.BPU.Transaction{}}
    end
  end
end


defmodule TestCache do
  use FBAgent.Cache
  def fetch_tx(txid, _opts \\ [], {adapter, adapter_opts}),
    do: adapter.fetch_tx(txid, adapter_opts)
end
