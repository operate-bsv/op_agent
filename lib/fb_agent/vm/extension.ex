defmodule FBAgent.VM.Extension do
  @moduledoc """
  Behaviour specification for extending the Lua VM.

  The Functional Bitcoin Lua VM can be easily extended, either with native Lua
  modules, or Elixir code that is added to the Lua VM as functions.

  ## Examples

      defmodule MyExtension do
        alias FBAgent.VM
        @behaviour Swoosh.Adapter

        def extend(vm) do
          vm
          |> VM.set!("msg", "hello world")
          |> VM.exec!("function hello() return msg end")
          |> VM.set_function!("sum", fn _vm, args -> apply(__MODULE__, :sum, args) end)
        end

        def sum(a,b) do
          a + b
        end
      end


  """
  alias FBAgent.VM

  @doc "Extends the given VM state, returning the modified state."
  @callback extend(VM.vt) :: VM.vt
end