defmodule Operate.Cache.NoCache do
  @moduledoc """
  Cache module for implementing no caching.

  This is the default cache module, and allows Operate to run without any
  caching, simply by forwarding and requests for tapes or ops to the
  configured adpater module(s) skipping any cache layers.
  """
  use Operate.Cache

end