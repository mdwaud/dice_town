defmodule DiceTown.PlayerTest do
  use ExUnit.Case, async: true

  alias DiceTown.Game.Player

  describe "init" do
    setup do
      player = Player.init
      %{player: player}
    end

    test "has correct # of coins", %{player: player} do
      assert 3 == player.coins
    end

    test "has correct buildings", %{player: player} do
      assert 1 == player.buildings[:wheat_field]
      assert 1 == player.buildings[:bakery]
    end
  end

  describe "earning income on a wheat_field" do
    setup context do
      player = %Player.PlayerState{buildings: context[:buildings], coins: 0}
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
      player = %Player.PlayerState{buildings: context[:buildings], coins: 0}
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
    test "bakery does not activate if owned on other player's turn", %{player: player} do
      assert nil == Player.earn_income(player, :bakery, 2, false)
    end

    @tag buildings: %{bakery: 0}
    test "bakery does not activate if not owned", %{player: player} do
      assert nil == Player.earn_income(player, :bakery, 2, true)
    end
  end

  describe "earning income on a cafe" do
    setup context do
      player = %Player.PlayerState{buildings: context[:buildings], coins: 0}
      %{player: player}
    end

    @tag buildings: %{cafe: 1}
    test "cafe does not activate if owned on own turn", %{player: player} do
      assert nil == Player.earn_income(player, :cafe, 3, true)
    end

    @tag buildings: %{cafe: 1}
    test "cafe activates if owned on other player's turn", %{player: player} do
      assert {:from_current_player, 1} == Player.earn_income(player, :cafe, 3, false)
    end

    @tag buildings: %{cafe: 0}
    test "cafe does not activate if not owned", %{player: player} do
      assert nil == Player.earn_income(player, :cafe, 3, false)
    end
  end

  describe "construction" do
    test "building a wheat_field with enough money" do
      player = %Player.PlayerState{buildings: %{}, coins: 1}

      {:ok, new_player_state} = Player.build(player, :wheat_field)

      assert 0 == new_player_state.coins
      assert %{wheat_field: 1} == new_player_state.buildings
    end

    test "building a wheat_field with insufficient money" do
      player = %Player.PlayerState{buildings: %{}, coins: 0}

      {:insufficient_coins, new_player_state} = Player.build(player, :wheat_field)

      assert 0 == new_player_state.coins
      assert %{} == new_player_state.buildings
      #assert %{wheat_field: 0} == player_state.buildings
    end

    test "building a unrecognized building returns an error" do
      player = %Player.PlayerState{buildings: %{}, coins: 3}

      {:unrecognized_building, new_player_state} = Player.build(player, :rocket_ship)

      assert 3 == new_player_state.coins
    end
  end
end