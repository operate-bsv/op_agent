defmodule Operate.VM.Extension do
  @moduledoc """
  Functional Bitcoin VM extension specification.

  The Functional Bitcoin Lua VM can be easily extended, either with native Lua
  modules, or Elixir code that is added to the Lua VM as functions.

  ## Examples

      defmodule MyExtension do
        use Operate.VM.Extension
        alias Operate.VMr

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
  alias Operate.VM

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      @behaviour Operate.VM.Extension

      def extends(vm), do: vm
    end
  end

  @doc "Extends the given VM state, returning the modified state."
  @callback extend(VM.vt) :: VM.vt
end