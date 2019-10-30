defmodule Operate.BPU.Script do
  @moduledoc """
  [Bitcoin Processing Unit](https://github.com/interplanaria/bpu) Script module.

  Provides methods for parsing and serializing input and output scripts to and
  from bare maps.
  """
  alias Operate.BPU.Cell
  
  defstruct i: nil, tape: [], e: nil

  @typedoc "BPU Script"
  @type t :: %__MODULE__{
    i: integer | nil,
    tape: [Cell.t, ...],
    e: InputEdge.t | OutputEdge.t
  }

  @input_edge_keys [:a, :h, :i]
  @output_edge_keys [:a, :i, :v]


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
      tape: Cell.from_map(params.tape),
      e: edge_from_map(params.e)
    ])
  end



  defp edge_from_map(source) when is_nil(source), do: nil
  defp edge_from_map(source) when is_map(source) do
    params = for {key, val} <- source, into: %{} do
      key = if is_atom(key), do: key, else: String.to_atom(key)
      {key, val}
    end

    case Map.keys(params) do
      k when k == @input_edge_keys -> params
      k when k == @output_edge_keys -> params
      _ -> nil
    end
  end

end