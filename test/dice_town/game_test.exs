defmodule DiceTown.GameTest do
  use ExUnit.Case

  alias DiceTown.Game

  describe "with two players" do
    setup do
      game = start_supervised!({Game, ["Player 1", "Player 2"]})
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
    end

    @tag :skip
    test "initial roll works" do
    end

    @tag :skip
    test "rolling a 1 pays everyone (wheat)" do
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
end