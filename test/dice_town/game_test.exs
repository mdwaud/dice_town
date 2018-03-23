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
    @tag :skip
    test "rolling a 3 with money pays a cafe owner" do
      # do setup
      opts = %{player_names: ["Player 1", "Player 2"], die_fn: always_roll(3)}
      game = start_supervised!({Game, opts})

      {game_state, actions} = Game.roll_dice(game, 0)

      # check game state
      assert 0 == game_state[:players][0].coins
      assert 1 == game_state[:players][1].coins
      assert :construction == game_state[:phase]
      assert 0 == game_state[:turn_player_id]
      assert [0,1] == game_state[:player_order]
      # check actions
      assert actions == [
        {:die_roll, 1},
        {:earn_income, %{player_id: 1, from: {:player, 0}, building: :cafe, amount: 1}}
      ]
    end

    @tag :skip
    test "rolling a 3 with no money (and someone owns a cafe) returns a failed EarnIncomeResult" do
    end

    @tag :skip
    test "handle partial cafe payment" do
    end
  end


  @tag :skip
  test "can buy a building" do
  end

  def always_roll(number) do
    fn() -> number end
  end
end