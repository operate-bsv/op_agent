defmodule FBAgent.BPU.Transaction do
  @moduledoc """
  [Bitcoin Processing Unit](https://github.com/interplanaria/bpu) Transaction module.

  Provides methods for parsing and serializing transactions to and from bare maps.
  """
  alias FBAgent.BPU.Script

  defstruct i: nil, txid: nil, in: [], out: [], blk: nil

  @typedoc "BPU Transaction"
  @type t :: %__MODULE__{
    i: integer | nil,
    txid: String.t | nil,
    in: [Script.t, ...],
    out: [Script.t, ...],
    blk: map | nil
  }

  @blk_keys [:i, :h, :t]

  
  @doc """
  Converts the given map or list of maps into a `__MODULE__.t`.
  """
  @spec from_map(map | list) :: __MODULE__.t | list
  def from_map(source) when is_list(source),
    do: source |> Enum.map(&from_map/1)
  
  def from_map(source) when is_map(source) do
    keys = Map.keys(%__MODULE__{})
    |> Enum.filter(& &1 != :__struct__)

    params = for key <- keys, into: %{} do
      value = Map.get(source, key) || Map.get(source, to_string(key))
      {key, value}
    end

    struct(__MODULE__, [
      i: params.i,
      txid: params.txid,
      in: Script.from_map(params.in),
      out: Script.from_map(params.out),
      blk: blk_from_map(params.blk)
    ])
  end


  defp blk_from_map(source) when is_nil(source), do: source
  defp blk_from_map(source) when is_map(source) do
    for key <- @blk_keys, into: %{} do
      value = Map.get(source, key) || Map.get(source, to_string(key))
      {key, value}
    end
  end

end