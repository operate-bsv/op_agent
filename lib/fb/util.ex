defmodule FB.Util do
  @moduledoc """
  Utility module containing commonly used helper functions.
  """


  @doc """
  Encodes the given query map into a Base64 encoded JSON string, Used commonly
  with Planaria adapters.

  ## Examples

      iex> %{"find" => %{"txid" => "abcdef"}}
      ...> |> FB.Util.encode_query
      "eyJmaW5kIjp7InR4aWQiOiJhYmNkZWYifX0="
  """
  @spec encode_query(map) :: String.t
  def encode_query(query) do
    query
    |> Jason.encode!
    |> Base.encode64
  end
  
end