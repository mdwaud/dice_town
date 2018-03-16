defmodule DiceTown.Game.Construction do
  alias DiceTown.Game
  alias DiceTown.Game.GameState

  @building_costs %{
    wheat_field: 1,
    bakery: 1,
    cafe: 2
  }

  def build(game_state, player_id, building) do
    cond do
      # check moneys that a building exists
      is_nil(@building_costs[building]) ->
        {:error, :does_not_exist}
      # check that there are buildings availabile
      game_state.buildings_available[building] == 0 ->
        {:error, :no_buildings_left}
      # check the player has enough money
      game_state.coins[player_id] < @building_costs[building] ->
        {:error, :insufficient_coins}
      # looks good
      true ->
        new_game_state = game_state
        |> GameState.build_building(player_id, building)
        |> GameState.pay_player(player_id, -@building_costs[building])
        {:ok, new_game_state}
    end
  end
end