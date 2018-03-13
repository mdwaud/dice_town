defmodule DiceTown.Game.ConstructionTest do
  use ExUnit.Case

  alias DiceTown.Game
  alias DiceTown.Game.Construction

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
    turn: %Game.GameTurn{
      player_id: 0,
      phase: :roll_dice
    }
  }

  describe "build" do
    test "with insufficient funds" do
      game_state = %Game.GameState{@initial_state_two_player |
        coins: %{
          0 => 0,
          1 => 0
        }
      }

      result = Construction.build(game_state, 0, :wheat_field)

      assert {:error, :insufficient_coins} == result
    end

    test "with no buildings left available" do
      game_state = %Game.GameState{@initial_state_two_player |
        buildings_available: %{
          wheat_field: 0
        }
      }

      result = Construction.build(game_state, 0, :wheat_field)

      assert {:error, :no_buildings_left} == result
    end

    test "with a building that doesn't exist" do
      game_state = @initial_state_two_player

      result = Construction.build(game_state, 0, :space_ship)

      assert {:error, :does_not_exist} == result
    end
  end
end