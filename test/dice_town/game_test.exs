defmodule DiceTown.GameTest do
  use ExUnit.Case, async: true

  alias DiceTown.Game

  @initial_two_player %{player_order: [0,1]}

  describe "with two players" do
    setup do
      game = start_supervised!({Game, @initial_two_player})
      %{game: game}
    end

    test "game sets up correctly", %{game: game} do
      game_state = Game.get_state(game)

      assert 3 == game_state[:players][0].coins
      assert 3 == game_state[:players][1].coins
      assert 1 == game_state[:players][0].buildings[:wheat_field]
      assert 1 == game_state[:players][1].buildings[:wheat_field]
      assert 1 == game_state[:players][0].buildings[:bakery]
      assert 1 == game_state[:players][1].buildings[:bakery]
      assert :roll_dice == game_state[:phase]
      assert 0 == game_state[:turn_player_id]
      assert [0,1] == game_state[:player_order]
    end
  end

  describe "setting up state" do
    test "can set up two users with arbitrary buildings and coins" do
      game_state = %{
        players: %{
          0 => %{
            buildings: %{
              wheat_field: 0,
              bakery: 0
            },
            coins: 10
          },
          1 => %{
            buildings: %{
              wheat_field: 3,
              bakery: 3
            },
            coins: 5
          },
        },
        phase: :roll_dice,
        turn_player_id: 0,
        player_order: [0,1]
      }
      game = start_supervised!({Game, %{game_state: game_state}})

      read_game_state = Game.get_state(game)

      assert game_state == read_game_state
    end
  end

  describe "rolling a 1" do
    setup do
      opts = @initial_two_player
      |> Map.merge(%{die_fn: always_roll(1)})
      game = start_supervised!({Game, opts})
      %{game: game}
    end

    test "pays everyone", %{game: game} do
      {game_state, _actions} = Game.roll_dice(game, 0)

      # check game state
      assert 4 == game_state[:players][0].coins
      assert 4 == game_state[:players][1].coins
      assert :construction == game_state[:phase]
      assert 0 == game_state[:turn_player_id]
      assert [0,1] == game_state[:player_order]
    end

    test "notifies with the correct actions", %{game: game} do
      {_game_state, actions} = Game.roll_dice(game, 0)

      # check actions
      assert actions == [
        {:die_roll, 1},
        {:earn_income, %{player_id: 1, from: :bank, building: :wheat_field, amount: 1}},
        {:earn_income, %{player_id: 0, from: :bank, building: :wheat_field, amount: 1}}
      ]
    end

    @tag :skip
    test "notifies everyone" do
    end

    @tag :skip
    test "only current player can roll the dice" do
    end
  end

  @tag :skip
  test "rolling a 2 pays roller (bakery)" do
  end

  @tag :skip
  test "rolling a 4 pays no one" do
  end

  describe "cafe" do
    test "rolling a 3 with money pays a cafe owner" do
      # do setup
      game_state = %{
        players: %{
          0 => %{
            buildings: %{},
            coins: 1
          },
          1 => %{
            buildings: %{
              cafe: 1
            },
            coins: 0
          },
        },
        phase: :roll_dice,
        turn_player_id: 0,
        player_order: [0,1]
      }
      game = start_supervised!({Game, %{game_state: game_state, die_fn: always_roll(3)}})

      {new_game_state, actions} = Game.roll_dice(game, 0)

      # check game state
      assert 0 == new_game_state[:players][0].coins
      assert 1 == new_game_state[:players][1].coins
      assert :construction == new_game_state[:phase]
      assert 0 == new_game_state[:turn_player_id]
      assert [0,1] == new_game_state[:player_order]
      # check actions
      assert actions == [
        {:die_roll, 3},
        {:earn_income, %{player_id: 1, from: {:player, 0}, building: :cafe, amount: 1}}
      ]
    end

    test "rolling a 3 with no money (and someone owns a cafe) returns a failed EarnIncomeResult" do
      # do setup
      game_state = %{
        players: %{
          0 => %{
            buildings: %{},
            coins: 0
          },
          1 => %{
            buildings: %{
              cafe: 1
            },
            coins: 0
          },
        },
        phase: :roll_dice,
        turn_player_id: 0,
        player_order: [0,1]
      }
      game = start_supervised!({Game, %{game_state: game_state, die_fn: always_roll(3)}})

      {new_game_state, actions} = Game.roll_dice(game, 0)

      # check game state
      assert 0 == new_game_state[:players][0].coins
      assert 0 == new_game_state[:players][1].coins
      assert :construction == new_game_state[:phase]
      assert 0 == new_game_state[:turn_player_id]
      assert [0,1] == new_game_state[:player_order]
      # check actions
      assert actions == [
        {:die_roll, 3},
        {:earn_income_miss, %{player_id: 1, from: {:player, 0}, building: :cafe, amount: 0}}
      ]
    end

    test "handle partial cafe payment" do
      # do setup
      game_state = %{
        players: %{
          0 => %{
            buildings: %{},
            coins: 1
          },
          1 => %{
            buildings: %{
              cafe: 2
            },
            coins: 0
          },
        },
        phase: :roll_dice,
        turn_player_id: 0,
        player_order: [0,1]
      }
      game = start_supervised!({Game, %{game_state: game_state, die_fn: always_roll(3)}})

      {new_game_state, actions} = Game.roll_dice(game, 0)

      # check game state
      assert 0 == new_game_state[:players][0].coins
      assert 1 == new_game_state[:players][1].coins
      assert :construction == new_game_state[:phase]
      assert 0 == new_game_state[:turn_player_id]
      assert [0,1] == new_game_state[:player_order]
      # check actions
      assert actions == [
        {:die_roll, 3},
        {:earn_income_partial, %{player_id: 1, from: {:player, 0}, building: :cafe, amount: 1}}
      ]
    end
  end

  describe "construction" do
    test "can build nothing" do
      # do setup
      game_state = %{
        players: %{
          0 => %{
            buildings: %{},
            coins: 1
          },
          1 => %{
            buildings: %{},
            coins: 0
          },
        },
        phase: :construction,
        turn_player_id: 0,
        player_order: [0,1]
      }
      game = start_supervised!({Game, %{game_state: game_state}})

      {new_game_state, actions} = Game.build(game, 0, nil)

      # check game state
      assert 1 == new_game_state[:players][0].coins
      assert 0 == new_game_state[:players][1].coins
      assert %{} == new_game_state[:players][0].buildings
      assert 1 == new_game_state[:turn_player_id]
      assert [0,1] == new_game_state[:player_order]
      assert actions == [
        {:construction, %{player_id: 0, building: nil}}
      ]
    end

    test "can buy a building" do
      # do setup
      game_state = %{
        players: %{
          0 => %{
            buildings: %{},
            coins: 1
          },
          1 => %{
            buildings: %{},
            coins: 0
          },
        },
        phase: :construction,
        turn_player_id: 0,
        player_order: [0,1]
      }
      game = start_supervised!({Game, %{game_state: game_state}})

      {new_game_state, actions} = Game.build(game, 0, :wheat_field)

      # check game state
      assert 0 == new_game_state[:players][0].coins
      assert 0 == new_game_state[:players][1].coins
      assert :roll_dice == new_game_state[:phase]
      assert 1 == new_game_state[:turn_player_id]
      assert [0,1] == new_game_state[:player_order]
      # check actions
      assert actions == [
        {:construction, %{player_id: 0, building: :wheat_field}}
      ]
    end

    test "errors if not enough to buy requested building" do
      # do setup
      game_state = %{
        players: %{
          0 => %{
            buildings: %{},
            coins: 1
          },
          1 => %{
            buildings: %{},
            coins: 0
          },
        },
        phase: :construction,
        turn_player_id: 0,
        player_order: [0,1]
      }
      game = start_supervised!({Game, %{game_state: game_state}})

      {:error, :insufficient_coins} = Game.build(game, 0, :cafe)
      read_game_state = Game.get_state(game)

      # check game state
      assert 1 == read_game_state[:players][0][:coins]
      assert 0 == read_game_state[:players][1][:coins]
      assert %{} == read_game_state[:players][0][:buildings]
      assert :construction == read_game_state[:phase]
      assert 0 == read_game_state[:turn_player_id]
      assert [0,1] == read_game_state[:player_order]
    end
  end

  def always_roll(number) do
    fn() -> number end
  end
end