defmodule DiceTown.Game.EarnIncomeTest do
  use ExUnit.Case

  alias DiceTown.Game
  alias DiceTown.Game.EarnIncome

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

  describe "building activations" do
    test "with two players and initial buildings should activate wheat" do
      buildings = @initial_state_two_player.buildings_built
      current_player_id = 0
      die_roll = 1

      building_activiations = EarnIncome.calc_building_activiations(buildings, current_player_id, die_roll)
      assert building_activiations == [
        %Game.BuildingActivation{
          building: :wheat_field,
          count: 1,
          to_player_id: 0,
          from_player_id: nil,
          total_amount: 1
        },
        %Game.BuildingActivation{
          building: :wheat_field,
          count: 1,
          to_player_id: 1,
          from_player_id: nil,
          total_amount: 1
        }
      ]
    end

    test "with two players and initial buildings should activate bakery" do
      buildings = @initial_state_two_player.buildings_built
      current_player_id = 0
      die_roll = 2

      building_activiations = EarnIncome.calc_building_activiations(buildings, current_player_id, die_roll)
      assert building_activiations == [
        %Game.BuildingActivation{
          building: :bakery,
          count: 1,
          to_player_id: 0,
          from_player_id: nil,
          total_amount: 1
        }
      ]
    end

    test "cafe should happen before bakery" do
      buildings = %{
        0 => %{
          bakery: 1
        },
        1 => %{
          cafe: 1
        }
      }
      current_player_id = 0
      die_roll = 3

      building_activiations = EarnIncome.calc_building_activiations(buildings, current_player_id, die_roll)
      assert building_activiations == [
        %Game.BuildingActivation{
          building: :cafe,
          count: 1,
          to_player_id: 1,
          from_player_id: 0,
          total_amount: 1
        },
        %Game.BuildingActivation{
          building: :bakery,
          count: 1,
          to_player_id: 0,
          from_player_id: nil,
          total_amount: 1
        }
      ]
    end
  end
end