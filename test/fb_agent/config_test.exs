defmodule FBAgent.ConfigTest do
  use ExUnit.Case
  doctest FBAgent.Config

  setup_all do
    {:ok, _pid} = FBAgent.Config.start_link()
    :ok
  end

  describe "FBAgent.Config.get/0" do
    test "must return vm and config state" do
      {vm, config} = FBAgent.Config.get
      assert is_tuple(vm)
      assert is_map(config)
    end
  end

end