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

    keys =
      Map.keys(struct(mod))
      |> Enum.filter(&(&1 != :__struct__))

    attrs =
      for key <- keys do
        val = Map.get(map, key) || Map.get(map, to_string(key))
        {key, restruct(val)}
      end

    struct(mod, attrs)
  end

  def restruct([head | rest]),
    do: [restruct(head) | restruct(rest)]

  def restruct(val), do: val

  @doc """
  converts a lua table back to elixir struct

  tuplelist = [
    {"__struct__", "Elixir.BSV.PrivKey"},
    {"compressed", true},
    {"d",
     <<152, 12, 110, 246, 195, 210, 240, 228, 109, 35, 145, 158, 135, 48, 12, 10,
       115, 251, 123, 203, 15, 54, 26, 75, 129, 185, 10, 43, 223, 5, 210, 45>>}
  ]

  output:
    %BSV.PubKey{
    compressed: true,
    point: %Curvy.Point{
      x: 82088944861703957177930580775501328651185625409420569396329737753348304696900,
      y: 44719512211966310551039175512542915384530845949753535174026330840076849401334
    }
    }

  """
  def lua_table_to_struct(table) do
    restruct(tuplelist_to_map(table))
  end

  defp tuplelist_to_map(tuplelist) do
    a_struct =
      Enum.reduce(tuplelist, [], fn elem, acc ->
        case elem do
          {k, maybe_struct} when is_list(maybe_struct) ->
            acc ++ [{k, tuplelist_to_map(maybe_struct)}]

          {a, b} ->
            acc ++ [{a, b}]

          _ ->
            acc
        end
      end)

    Enum.into(a_struct, %{})
  end

  @doc """
  a list in elixir such as this:

  original = [
    <<116, 66, 140, 64, 43, 144, 54, 197, 38, 126, 89>>,
    <<255, 39, 72, 204, 45, 248, 185, 27, 36, 195, 128, 152, 183, 220, 229, 31>>
  ]

  passed into lua, turns into a table and in an Elixir fn call, looks like this:

  table = [
    {1, <<116, 66, 140, 64, 43, 144, 54, 197, 38, 126, 89>>},
    {2,
     <<255, 39, 72, 204, 45, 248, 185, 27, 36, 195, 128, 152, 183, 220, 229, 31>>}
  ]

    This fn changes it back.

  """
  def lua_table_to_list(table) do
    Enum.into(table, [], fn {_k, v} -> v end)
  end
end
