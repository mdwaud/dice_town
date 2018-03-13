defmodule DiceTown.Game.EarnIncome do
  alias DiceTown.Game
  alias DiceTown.Game.BuildingActivation
  alias DiceTown.Game.EarnIncomeResult

  @building_order Enum.reverse([:wheat_field, :bakery, :cafe])

  def calc_building_activiations(buildings, current_player_id, die_roll) do
    @building_order
    |> Enum.flat_map(fn(building) -> calc_building_activiations(buildings, current_player_id, die_roll, building) end)
    |> List.flatten
  end

  def apply_building_activations(game_state, building_activations) do
    apply_building_activations(game_state, building_activations, [])
  end

  def apply_building_activations(game_state, [], earn_income_results) do
    {game_state, earn_income_results}
  end
  def apply_building_activations(game_state, building_activations, earn_income_results) do
    [building_activation | remaining_activations] = building_activations
# todo: cafe stuff here
    {new_game_state, new_earn_income_result} = resolve_activation(game_state, building_activation)

    apply_building_activations(new_game_state, remaining_activations, earn_income_results ++ [new_earn_income_result])
  end

  # buildings

# figure out if the building is activated
  def calc_building_activiations(buildings, current_player_id, 1, :wheat_field) do
    buildings
    |> Enum.map(fn({player_id, building_map}) -> activate_building(building_map, player_id, current_player_id, :wheat_field) end)
  end
  def calc_building_activiations(_, _, _, :wheat_field), do: []

  def calc_building_activiations(buildings, current_player_id, die_roll, :bakery) when die_roll >= 2 and die_roll <= 3 do
    activate_building(buildings[current_player_id], current_player_id, current_player_id, :bakery)
  end
  def calc_building_activiations(_, _, _, :bakery), do: []

  def calc_building_activiations(buildings, current_player_id, 3, :cafe) do
    buildings
    |> Enum.map(fn({player_id, building_map}) -> activate_building(building_map, player_id, current_player_id, :cafe) end)
  end
  def calc_building_activiations(_, _, _, :cafe), do: []

# figure out the amount (if any)
  def activate_building(%{wheat_field: count}, player_id, _current_player_id, :wheat_field) when count > 0 do
    [
      %BuildingActivation{
        building: :wheat_field,
        count: count,
        to_player_id: player_id,
        from_player_id: nil,
        total_amount: count
      }
    ]
  end

  def activate_building(%{bakery: count}, player_id, player_id, :bakery) when count > 0 do
    [
      %BuildingActivation{
        building: :bakery,
        count: count,
        to_player_id: player_id,
        from_player_id: nil,
        total_amount: count
      }
    ]
  end

  def activate_building(%{cafe: count}, player_id, current_player_id, :cafe) when count > 0 and player_id != current_player_id do
    [
      %BuildingActivation{
        building: :cafe,
        count: count,
        to_player_id: player_id,
        from_player_id: current_player_id,
        total_amount: count
      }
    ]
  end

  def activate_building(_, _, _, _), do: []

  # this is mostly to deal with actions that might fails (ex: paying another player)

  def resolve_activation(game_state, building_activation = %BuildingActivation{from_player_id: nil}) do
    new_game_state = pay_player(game_state, building_activation.to_player_id, building_activation.total_amount)
    new_earn_income_result = %EarnIncomeResult{
      building_activation: building_activation,
      success: true
    }
    {new_game_state, new_earn_income_result}
  end

  # stealing money from a player
  def resolve_activation(game_state, building_activation) do
    cond do
      game_state.coins[building_activation.from_player_id] >= building_activation.total_amount ->
        new_game_state = pay_player(game_state, building_activation.to_player_id, building_activation.total_amount)
        new_game_state = pay_player(game_state, building_activation.from_player_id, -building_activation.total_amount)
        new_earn_income_result = %EarnIncomeResult{
          building_activation: building_activation,
          success: true
        }
        {new_game_state, new_earn_income_result}
      true ->
        total_amount = game_state.coins[building_activation.from_player_id]
        new_game_state = pay_player(game_state, building_activation.to_player_id, total_amount)
        new_game_state = pay_player(game_state, building_activation.from_player_id, -total_amount)
        new_earn_income_result = %EarnIncomeResult{
          building_activation: building_activation,
          success: false
        }
        {new_game_state, new_earn_income_result}
    end
  end

  # utility methods

  def pay_player(game_state, player_id, amount) do
    %Game.GameState{game_state | coins: %{
      game_state.coins | player_id => game_state.coins[player_id] + amount
    }}
  end
end