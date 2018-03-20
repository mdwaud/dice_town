defmodule DiceTown.GameTest do
  use ExUnit.Case, async: true

  alias DiceTown.Game

  describe "with two players" do
    setup do
      game = start_supervised!({Game, %{player_names: ["Player 1", "Player 2"]}})
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

  describe "rolling a 1" do
    setup do
      opts = %{player_names: ["Player 1", "Player 2"], die_fn: always_roll(1)}
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

    @tag :skip
    test "notifies everyone", %{game: game} do
      {_game_state, actions} = Game.roll_dice(game, 0)

      # check actions
      assert actions == [
        {:die_roll, 1},
        {:earn_income, %{player_id: 0, from: :bank, building: :wheat_field, amount: 1}},
        {:earn_income, %{player_id: 1, from: :bank, building: :wheat_field, amount: 1}}
      ]
    end

    @tag :skip
    test "only current player can roll the dice" do
    end

    @tag :skip
    test "rolling a 2 pays roller (bakery)" do
    end

    @tag :skip
    test "rolling a 4 pays no one" do
    end

    @tag :skip
    test "rolling a 3 with no money (and someone owns a cafe) returns a failed EarnIncomeResult" do
    end

    @tag :skip
    test "handle partial cafe payment" do
    end

    @tag :skip
    test "can buy a building" do
    end
  end

  def always_roll(number) do
    fn() -> number end
  end
end