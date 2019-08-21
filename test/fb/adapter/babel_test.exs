defmodule FB.Adapter.BabelTest do
  use ExUnit.Case
  alias FB.Adapter.Babel
  doctest FB.Adapter.Babel

  describe "FB.Adapter.Babel.get_tape/1" do

    setup do
      Tesla.Mock.mock fn
        _ -> File.read!("test/mocks/babel_get_tape.json") |> Jason.decode! |> Tesla.Mock.json
      end
      :ok
    end

    test "get tape" do
      res = Babel.get_tape("98be5010028302399999bfba0612ee51ea272e7a0eb3b45b4b8bef85f5317633", api_key: "test")
      assert length(res.cells) == 3
      assert List.first(res.cells).ref == "19HxigV4QyBv3tHpQVcUEQyq1pzZVdoAut"
      assert length(List.first(res.cells).params) == 4
    end
    
  end

end