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
      bakery: 8,
      cafe: 8
    },
    turn: %Game.GameTurn{
      player_id: 0,
      phase: :roll_dice
    }
  }

  @cafe_bankrupt_game_state %Game.GameState{
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
        bakery: 1
      },
      1 => %{
        cafe: 1
      }
    },
    coins: %{
      0 => 0,
      1 => 0
    },
    buildings_available: %{
      wheat_field: 8,
      bakery: 7,
      cafe: 7
    },
    turn: %Game.GameTurn{
      player_id: 0,
      phase: :earn_income
    }
  }


  describe "with two players" do
    test "game sets up correctly " do
      game_state = Game.init_game_state(["Player 1", "Player 2"])

      assert game_state == @initial_state_two_player
    end

    test "initial roll works" do
      game_state = @initial_state_two_player

      {:die_roll, result, new_game_state} = Game.roll_dice(game_state, 0)
      %{player_id: player_id, die_roll: die_roll} = result

      assert 0 == player_id
      assert 1 >= die_roll >= 6
      assert 0 == new_game_state.turn.player_id
      assert :earn_income == new_game_state.turn.phase
    end

    test "rolling a 1 pays everyone (wheat)" do
      game_state = %Game.GameState{@initial_state_two_player | turn: %Game.GameTurn{
        player_id: 0,
        phase: :earn_income
      }}

      {:earned_income, earn_income_results, new_game_state} = Game.earn_income(game_state, 0, 1)

      # check earn_income_results
      assert 2 == length(earn_income_results)
      assert List.first(earn_income_results) == %Game.EarnIncomeResult{
        building_activation: %Game.BuildingActivation{
          building: :wheat_field,
          count: 1,
          to_player_id: 0,
          from_player_id: nil,
          total_amount: 1
        },
        success: true
      }
      assert List.last(earn_income_results) == %Game.EarnIncomeResult{
        building_activation: %Game.BuildingActivation{
          building: :wheat_field,
          count: 1,
          to_player_id: 1,
          from_player_id: nil,
          total_amount: 1
        },
        success: true
      }
      # check moneys
      assert 4 == new_game_state.coins[0]
      assert 4 == new_game_state.coins[1]
      # check turn state
      assert 0 == new_game_state.turn.player_id
      assert :construction == new_game_state.turn.phase
    end

    test "rolling a 2 pays roller (bakery)" do
      game_state = %Game.GameState{@initial_state_two_player | turn: %Game.GameTurn{
        player_id: 0,
        phase: :earn_income
      }}

      {:earned_income, earn_income_results, new_game_state} = Game.earn_income(game_state, 0, 2)

      # check earn_income_results
      assert 1 == length(earn_income_results)
      assert List.first(earn_income_results) == %Game.EarnIncomeResult{
        building_activation: %Game.BuildingActivation{
          building: :bakery,
          count: 1,
          to_player_id: 0,
          from_player_id: nil,
          total_amount: 1
        },
        success: true
      }
      # check moneys
      assert 4 == new_game_state.coins[0]
      assert 3 == new_game_state.coins[1]
      # check turn state
      assert 0 == new_game_state.turn.player_id
      assert :construction == new_game_state.turn.phase
    end

    test "rolling a 4 pays no one" do
      game_state = %Game.GameState{@initial_state_two_player | turn: %Game.GameTurn{
        player_id: 0,
        phase: :earn_income
      }}

      {:earned_income, [], new_game_state} = Game.earn_income(game_state, 0, 4)

      # check moneys
      assert 3 == new_game_state.coins[0]
      assert 3 == new_game_state.coins[1]
      # check turn state
      assert 0 == new_game_state.turn.player_id
      assert :construction == new_game_state.turn.phase
    end

    test "rolling a 3 with no money (and someone owns a cafe) returns a failed EarnIncomeResult" do
      game_state = %Game.GameState{@cafe_bankrupt_game_state | turn: %Game.GameTurn{
        player_id: 0,
        phase: :earn_income
      }}

      {:earned_income, earn_income_results, new_game_state} = Game.earn_income(game_state, 0, 3)

      # check earn_income_results
      assert 2 == length(earn_income_results)
      assert List.first(earn_income_results) == %Game.EarnIncomeResult{
        building_activation: %Game.BuildingActivation{
          building: :cafe,
          count: 1,
          to_player_id: 1,
          from_player_id: 0,
          total_amount: 1
        },
        success: false
      }
      assert List.last(earn_income_results) == %Game.EarnIncomeResult{
        building_activation: %Game.BuildingActivation{
          building: :bakery,
          count: 1,
          to_player_id: 0,
          from_player_id: nil,
          total_amount: 1
        },
        success: true
      }
      # check moneys
      assert 1 == new_game_state.coins[0]
      assert 0 == new_game_state.coins[1]
      # check turn state
      assert 0 == new_game_state.turn.player_id
      assert :construction == new_game_state.turn.phase
    end

    test "handle partial cafe payment" do
      game_state = %Game.GameState{@cafe_bankrupt_game_state | turn: %Game.GameTurn{
        player_id: 0,
        phase: :earn_income
      },
        buildings_built: %{
          0 => %{
            bakery: 1
          },
          1 => %{
            cafe: 2
          }
        },
        coins: %{
          0 => 1,
          1 => 0
        }
      }

      {:earned_income, earn_income_results, new_game_state} = Game.earn_income(game_state, 0, 3)

      # check earn_income_results
      assert 2 == length(earn_income_results)
      assert List.first(earn_income_results) == %Game.EarnIncomeResult{
        building_activation: %Game.BuildingActivation{
          building: :cafe,
          count: 2,
          to_player_id: 1,
          from_player_id: 0,
          total_amount: 2
        },
        success: false
      }
      assert List.last(earn_income_results) == %Game.EarnIncomeResult{
        building_activation: %Game.BuildingActivation{
          building: :bakery,
          count: 1,
          to_player_id: 0,
          from_player_id: nil,
          total_amount: 1
        },
        success: true
      }
      # check moneys
      assert 1 == new_game_state.coins[0]
      assert 1 == new_game_state.coins[1]
      # check turn state
      assert 0 == new_game_state.turn.player_id
      assert :construction == new_game_state.turn.phase
    end

    test "can buy a building" do
      game_state = %Game.GameState{@initial_state_two_player | turn: %Game.GameTurn{
        player_id: 0,
        phase: :construction
      }}

      {:built, :wheat_field, new_game_state} = Game.build(game_state, 0, :wheat_field)

      # check moneys
      assert 2 == new_game_state.coins[0]
      assert 3 == new_game_state.coins[1]
      # check turn state
      assert 1 == new_game_state.turn.player_id
      assert :roll_dice == new_game_state.turn.phase
    end
  end

  describe "utility methods" do
    test "next_player incremental" do
      game_state = @initial_state_two_player

      assert 1 == Game.next_player(game_state)
    end

    test "next_player full revolution" do
      game_state = %Game.GameState{@initial_state_two_player | turn: %Game.GameTurn{
        player_id: 1,
        phase: :construction
      }}

      assert 0 == Game.next_player(game_state)
    end
  end
end