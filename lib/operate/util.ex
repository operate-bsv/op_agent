defmodule Operate.Util do
  @moduledoc """
  A collection of commonly used helper functions.
  """

  
  @doc """
  Converts the given map into a struct. Must be used with a struct that has
  previously been serialised into a map with stringified keys and still contains
  the `"__struct__"` key.

  ## Examples

      iex> test = Operate.Util.restruct(%{"__struct__" => "Elixir.Operate.Cell"})
      ...> test.__struct__ == Operate.Cell
      true
  """
  @spec restruct(map) :: struct
  
  def restruct(%{"__struct__" => mod_str} = map) do
    mod = String.to_atom(mod_str)

    keys = Map.keys(struct(mod))
    |> Enum.filter(& &1 != :__struct__)

    attrs = for key <- keys do
      val = Map.get(map, key) || Map.get(map, to_string(key))
      {key, restruct(val)}
    end

    struct(mod, attrs)
  end

  def restruct([head | rest]),
    do: [restruct(head) | restruct(rest)]

  def restruct(val), do: val

end