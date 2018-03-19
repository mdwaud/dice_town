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
      player = start_supervised!({Player, %{buildings: context[:buildings]}})
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
      player = start_supervised!({Player, %{buildings: %{}, coins: 1}})

      :ok = Player.build(player, :wheat_field)
      player_state = Player.get_state(player)

      assert 0 == player_state.coins
      assert %{wheat_field: 1} == player_state.buildings
    end

    test "building a wheat_field with insufficient money" do
      player = start_supervised!({Player, %{buildings: %{}, coins: 0}})

      :insufficient_coins = Player.build(player, :wheat_field)
      player_state = Player.get_state(player)

      assert 0 == player_state.coins
      assert %{} == player_state.buildings
      #assert %{wheat_field: 0} == player_state.buildings
    end

    test "building a unrecognized building returns an error" do
      player = start_supervised!(Player)

      :unrecognized_building = Player.build(player, :rocket_ship)
      player_state = Player.get_state(player)

      assert 3 == player_state.coins
    end
  end
end