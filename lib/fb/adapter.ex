defmodule FB.Adapter do
  @moduledoc """
  The Function Bitcoin adapter specification,

  An adapter is any module responsible for loading tapes and procs from a
  datasource - normally a web API or a database. The module must export:

  * `get_tape/2` - function that takes a txid and returns a `t:FB.Tape.t` object.
  * `get_procs/2` - function that takes an array of procedure references and
  returns an array of scripts.
  """

  @callback get_tape(String.t, keyword) :: {:ok, FB.Tape.t} | {:error, String.t}
  @callback get_tape!(String.t, keyword) :: FB.Tape.t
  @callback get_procs(list | FB.Tape.t, keyword) :: {:ok, list | FB.Tape.t} | {:error, String.t}
  @callback get_procs!(list | FB.Tape.t, keyword) :: list | FB.Tape.t
  
end