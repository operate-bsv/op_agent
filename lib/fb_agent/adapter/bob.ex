defmodule FBAgent.Adapter.Bob do
  @moduledoc """
  Adapter module for loading tapes and procedure scripts from [BOB](https://bob.planaria.network).

  ## Examples

      FBAgent.Adapter.Bob.get_tape(txid)
      # => {:ok, %FBAgent.Tape{}}
  """
  alias FBAgent.Tape
  alias FBAgent.Cell
  use Tesla, only: [:get], docs: false

  plug Tesla.Middleware.BaseUrl, "https://bob.planaria.network/q/1GgmC7Cg782YtQ6R9QkM58voyWeQJmJJzG/"
  plug Tesla.Middleware.JSON

  @behaviour FBAgent.Adapter


  @doc """
  Fetches a transaction by the given txid, and maps it into a tape.
  """
  @impl FBAgent.Adapter
  @spec get_tape(String.t, keyword) :: {:ok, Tape.t} | {:error, String.t}
  def get_tape(txid, options \\ []) do
    api_key = Keyword.get(options, :api_key)
    path = FBAgent.Util.encode_query(%{
      "v" => "3",
      "q" => %{
        "find" => %{
          "tx.h" => txid,
          "out.tape.cell" => %{
            "$elemMatch" => %{
              "ii" => 0,
              "op" => 106
            }
          }
        },
        "limit" => 1
      }
    })
    case get(path, headers: [key: api_key]) do
      {:ok, res} ->
        tape = to_tape(res.body) |> List.first
        {:ok, tape}
      error -> error
    end
  end


  @doc """
  As `f:FBAgent.Adapter.Bob.get_tape/2`, but returns the tape or raises an exception.
  """
  @impl FBAgent.Adapter
  @spec get_tape!(String.t, keyword) :: Tape.t
  def get_tape!(txid, options \\ []) do
    case get_tape(txid, options) do
      {:ok, tape} -> tape
      {:error, err} -> raise err
    end
  end


  @doc """
  TODOC
  """
  def cache_get_tape(txid, options \\ []) do
    key = "t:#{txid}"
    ConCache.fetch_or_store(:fb_agent, key, fn -> get_tape(txid, options) end)
  end


  @doc """
  Not implemented.
  """
  @impl FBAgent.Adapter
  @spec get_procs(list, keyword) :: Tape.t
  def get_procs(_refs, _options \\ []), do: raise "FBAgent.Adapter.Bob.get_procs/2 not implemented"


  @doc """
  Not implemented.
  """
  @impl FBAgent.Adapter
  @spec get_procs!(list, keyword) :: Tape.t
  def get_procs!(_refs, _options \\ []), do: raise "FBAgent.Adapter.Bob.get_procs!/2 not implemented"
  

  defp to_tape(%{"u" => u, "c" => c}) do
    Enum.map(u ++ c, &to_tape/1)
  end

  defp to_tape(tx) do
    out = Enum.find(tx["out"], &op_return_output?/1)
    cells = out["tape"]
    |> Enum.reject(&op_return_cell?/1)
    |> Enum.map(&to_cell/1)
    %Tape{ tx: tx, cells: cells }
  end


  defp to_cell(%{"cell" => [head | tail]}) do
    str = Base.decode64!(head["b"])
    ref = case String.valid?(str) do
      true  -> str
      false -> Base.encode16(str, case: :lower)
    end
    params = Enum.map(tail, &decode_param/1)
    %Cell{ref: ref, params: params}
  end

  
  defp decode_param(%{"lb" => b}), do: Base.decode64!(b)
  defp decode_param(%{"b" => b}), do: Base.decode64!(b)
  defp decode_param(_), do: nil


  defp op_return_output?(out) do
    is_map(out) && out["tape"] |> List.first |> op_return_cell?
  end
  

  defp op_return_cell?(%{"cell" => cell}) do
    Enum.any?(cell, &(&1["op"] == 106))
  end

end