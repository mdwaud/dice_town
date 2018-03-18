defmodule DiceTown.PlayerTest do
  use ExUnit.Case, async: true

  alias DiceTown.Game.Player

  describe "init" do
    setup do
      player = start_supervised!(Player)
      %{player: player}
    end

    test "has correct # of coins", %{player: player} do
      assert 3 == Player.get_state(player).coins
    end

    test "has correct buildings", %{player: player} do
      assert 1 == Player.get_state(player).buildings[:wheat_field]
      assert 1 == Player.get_state(player).buildings[:bakery]
    end
  end

  describe "earning income on a wheat_field" do
    setup context do
      player = start_supervised!({Player, %{buildings: context[:buildings]}})
      %{player: player}
    end

    @tag buildings: %{wheat_field: 1}
    test "wheat_field activates if owned on own turn", %{player: player} do
      assert {:from_bank, 1} == Player.earn_income(player, :wheat_field, 1, true)
    end

    @tag buildings: %{wheat_field: 1}
    test "wheat_field activates if owned on other player's turn turn", %{player: player} do
      assert {:from_bank, 1} == Player.earn_income(player, :wheat_field, 1, false)
    end

    @tag buildings: %{wheat_field: 0}
    test "wheat_field does not activate if not owned", %{player: player} do
      assert nil == Player.earn_income(player, :wheat_field, 1, true)
    end
  end

  describe "earning income on a bakery" do
    setup context do
      player = start_supervised!({Player, %{buildings: context[:buildings]}})
      %{player: player}
    end

    @tag buildings: %{bakery: 1}
    test "bakery activates if owned on own turn", %{player: player} do
      assert {:from_bank, 1} == Player.earn_income(player, :bakery, 2, true)
    end

    @tag buildings: %{bakery: 1}
    test "bakery activates if owned on other player's turn", %{player: player} do
      assert {:from_bank, 1} == Player.earn_income(player, :bakery, 3, true)
    end

    @tag buildings: %{bakery: 1}
    test "bakery activates if owned on other player's turn turn", %{player: player} do
      assert nil == Player.earn_income(player, :bakery, 2, false)
    end

    @tag buildings: %{bakery: 0}
    test "bakery does not activate if not owned", %{player: player} do
      assert nil == Player.earn_income(player, :bakery, 2, true)
    end
  end
end