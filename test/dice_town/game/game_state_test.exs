defmodule DiceTown.GameStateTest do
  use ExUnit.Case

  alias DiceTown.Game.GameState

  @initial_state_two_player %GameState{
    players: [
      %GameState.Player{
        id: 0,
        name: "Player 1"
      },
      %GameState.Player{
        id: 1,
        name: "Player 2"
      }
    ],
    buildings_built: %{
      0 => %{
        wheat_field: 1,
        bakery: 1
      },
      1 => %{
        wheat_field: 1,
        bakery: 1
      }
    },
    coins: %{
      0 => 3,
      1 => 3
    },
    buildings_available: %{
      wheat_field: 8,
      bakery: 8
    },
    turn: %GameState.GameTurn{
      player_id: 0,
      phase: :roll_dice
    }
  }

  describe "next_player" do
    test "next_player incremental" do
      game_state = @initial_state_two_player

      assert 1 == GameState.get_next_player(game_state)
    end

    test "next_player full revolution" do
      game_state = %GameState{@initial_state_two_player | turn: %GameState.GameTurn{
        player_id: 1,
        phase: :construction
      }}

      assert 0 == GameState.get_next_player(game_state)
    end
  end
end