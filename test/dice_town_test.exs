defmodule DiceTownTest do
  use ExUnit.Case

  test "game setup with one player" do
    game_state = DiceTown.GameServer.init_game_state(["Player 1"])

    assert game_state == %DiceTown.GameServer.GameState{
      players: [
        %DiceTown.GameServer.Player{
          id: 0,
          name: "Player 1"
        }
      ],
      buildings_built: %{
        0 => %{
          wheat_field: 1,
          ranch: 1
        }
      }
    }
  end
end