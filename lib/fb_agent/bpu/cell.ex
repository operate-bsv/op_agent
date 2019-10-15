defmodule FBAgent.BPU.Cell do
  @moduledoc """
  [Bitcoin Processing Unit](https://github.com/interplanaria/bpu) Cell module.

  Provides methods for parsing and serializing cells to and from bare maps.
  """
  defstruct i: nil, cell: %{}

  @typedoc "BPU Cell"
  @type t :: %__MODULE__{
    i: integer,
    cell: map
  }
  #@type t :: %__MODULE__{
  #  i: integer,
  #  ii: integer,
  #  b: String.t | nil,
  #  s: String.t | nil,
  #  op: integer | nil,
  #  ops: String.t | nil
  #}

  @cell_keys [:i, :ii, :b, :lb, :s, :ls, :op, :ops]
  

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
      cell: cell_data_from_map(params.cell),
    ])
  end
  

  defp cell_data_from_map(source) when is_list(source),
    do: source |> Enum.map(&cell_data_from_map/1)

  defp cell_data_from_map(source) when is_map(source) do
    Enum.reduce_while(@cell_keys, %{}, fn(key, params) ->
      value = Map.get(source, key) || Map.get(source, to_string(key))
      {:cont, cell_attribute({key, value}, params)}
    end)
  end
  

  defp cell_attribute({_k, nil}, params), do: params

  defp cell_attribute({k, v}, params) when k in [:b, :lb],
    do: Map.put(params, :b, v)

  defp cell_attribute({k, v}, params) when k in [:s, :ls],
    do: Map.put(params, :s, v)

  defp cell_attribute({k, v}, params),
    do: Map.put(params, k, v)

end