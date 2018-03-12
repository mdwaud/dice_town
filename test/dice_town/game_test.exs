defmodule DiceTown.GameTest do
  use ExUnit.Case

  alias DiceTown.Game

  @initial_state_two_player %Game.GameState{
    players: [
      %Game.Player{
        id: 0,
        name: "Player 1"
      },
      %Game.Player{
        id: 1,
        name: "Player 2"
      }
    ],
    buildings_built: %{
      0 => %{
        wheat_field: 1,
        ranch: 1
      },
      1 => %{
        wheat_field: 1,
        ranch: 1
      }
    },
    coins: %{
      0 => 3,
      1 => 3
    },
    buildings_available: %{
      wheat_field: 8,
      ranch: 8
    },
    turn: %Game.GameTurn{
      player_id: 0,
      phase: :roll_dice
    }
  }

  describe "with two players" do
    test "game sets up correctly " do
      game_state = Game.init_game_state(["Player 1", "Player 2"])

      assert game_state == @initial_state_two_player
    end

    test "initial roll works" do
      game_state = @initial_state_two_player

      {:die_roll, die_roll, new_game_state} = Game.roll_dice(game_state)

      assert 1 >= die_roll >= 6
      assert 0 == new_game_state.turn.player_id
      assert :earn_income == new_game_state.turn.phase

    end
  end
end