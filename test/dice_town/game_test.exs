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

    test "rolling a 1 pays everyone (wheat)" do
      game_state = %Game.GameState{@initial_state_two_player | turn: %Game.GameTurn{
        player_id: 0,
        phase: :earn_income
      }}

      {:earned_income, [], new_game_state} = Game.earn_income(game_state, 1)

      # check moneys
      assert 4 == new_game_state.coins[0]
      assert 4 == new_game_state.coins[1]
      # check turn state
      assert 0 == new_game_state.turn.player_id
      assert :construction == new_game_state.turn.phase
    end

    @tag :skip
    test "rolling a 2 pays roller (bakery)" do

    end

    test "rolling a 4 pays no one" do
      game_state = %Game.GameState{@initial_state_two_player | turn: %Game.GameTurn{
        player_id: 0,
        phase: :earn_income
      }}

      {:earned_income, [], new_game_state} = Game.earn_income(game_state, 4)

      # check moneys
      assert 3 == new_game_state.coins[0]
      assert 3 == new_game_state.coins[1]
      # check turn state
      assert 0 == new_game_state.turn.player_id
      assert :construction == new_game_state.turn.phase
    end
  end
end