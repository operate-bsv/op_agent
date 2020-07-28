ExUnit.start()


defmodule TestAdapter do
  use Operate.Adapter
  def fetch_tx(txid, _opts \\ []) do
    case txid do
      nil -> {:error, "Test error"}
      _ -> {:ok, %Operate.BPU.Transaction{}}
    end
  end

  def fetch_tx_by(query, _opts \\ []) do
    case query do
      nil -> {:error, "Test error"}
      _ -> {:ok, [%Operate.BPU.Transaction{}]}
    end
  end
end


defmodule TestCache do
  use Operate.Cache
end


Supervisor.start_link([
  {Plug.Cowboy, [
    scheme: :http,
    plug: MockServer,
    options: [port: 8088]
  ]}
], [strategy: :one_for_one])
