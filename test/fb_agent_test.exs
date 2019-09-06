defmodule FBAgentTest do
  use ExUnit.Case
  doctest FBAgent

  setup_all do
    {:ok, _pid} = FBAgent.start_link()
    :ok
  end

  describe "FBAgent.state/0" do
    test "must return vm and config state" do
      {vm, config} = FBAgent.state
      assert is_tuple(vm)
      assert is_map(config)
    end
  end

end
