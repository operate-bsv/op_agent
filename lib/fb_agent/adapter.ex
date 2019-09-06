defmodule FBAgent.Adapter do
  @moduledoc """
  The Function Bitcoin adapter specification,

  An adapter is any module responsible for loading tapes and procs from a
  datasource - normally a web API or a database. The module must export:

  * `get_tape/2` - function that takes a txid and returns a `t:FBAgent.Tape.t` object.
  * `get_procs/2` - function that takes an array of procedure references and
  returns an array of scripts.
  """

  @callback get_tape(String.t, keyword) :: {:ok, FBAgent.Tape.t} | {:error, String.t}
  @callback get_tape!(String.t, keyword) :: FBAgent.Tape.t
  @callback get_procs(list | FBAgent.Tape.t, keyword) :: {:ok, list | FBAgent.Tape.t} | {:error, String.t}
  @callback get_procs!(list | FBAgent.Tape.t, keyword) :: list | FBAgent.Tape.t
  
end