defmodule DiceTown.GameTest do
  use ExUnit.Case

  test "game setup with one player" do
    game_state = DiceTown.Game.init_game_state(["Player 1"])

    assert game_state == %DiceTown.Game.GameState{
      players: [
        %DiceTown.Game.Player{
          id: 0,
          name: "Player 1"
        }
      ],
      buildings_built: %{
        0 => %{
          wheat_field: 1,
          ranch: 1
        }
      },
      coins: %{
        0 => 3
      },
      buildings_available: %{
        wheat_field: 8,
        ranch: 8
      },
      turn: %DiceTown.Game.GameTurn{
        player_id: 0,
        phase: :roll_dice
      }
    }
  end
end