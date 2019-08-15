defmodule FBTest do
  use ExUnit.Case
  doctest FB

  test "greets the world" do
    assert FB.hello() == :world
  end
end
