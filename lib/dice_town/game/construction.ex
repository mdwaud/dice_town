defmodule DiceTown.Game.Construction do
  alias DiceTown.Game
  alias DiceTown.Game.GameState

  @building_costs %{
    wheat_field: 1,
    bakery: 1,
    cafe: 2
  }

  def build(game_state, player_id, building) do
    new_game_state = game_state
    # todo: check moneys
    # todo: check building availability
    |> build_building(player_id, building)
    |> pay_player(player_id, -@building_costs[building])
    {:ok, new_game_state}
  end

  # actually build the building
  def build_building(game_state, player_id, building) do
    %GameState{game_state | buildings_built: %{game_state.buildings_built |
      player_id => %{game_state.buildings_built[player_id] |
        building => game_state.buildings_built[player_id][building] + 1
      }
    }}
  end

  # utility methods

  def pay_player(game_state, player_id, amount) do
    %Game.GameState{game_state | coins: %{
      game_state.coins | player_id => game_state.coins[player_id] + amount
    }}
  end
end