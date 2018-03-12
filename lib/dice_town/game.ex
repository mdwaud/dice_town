defmodule DiceTown.Game do
  # state struct

  defmodule Player do
    defstruct id: nil, name: nil
  end

  defmodule GameTurn do
    defstruct player_id: nil, phase: nil
  end

  defmodule GameState do
    defstruct players: [], buildings_built: %{}, buildings_available: %{}, coins: %{}, turn: nil
  end

  defmodule BuildingActivation do
    defstruct building: nil, count: nil, to_player_id: nil, from_player_id: nil, total_amount: nil
  end

  # game logic

  def init_game_state(player_names) do
    players = player_names
    |> Enum.with_index
    |> Enum.map( fn({name, index}) -> %Player{id: index, name: name} end )

    player_ids = players
    |> Enum.map( fn(%Player{id: id}) -> id end)

    buildings_built = player_ids
    |> Enum.map( fn(id) -> {id, %{wheat_field: 1, bakery: 1}} end)
    |> Map.new

    coins = player_ids
    |> Enum.map( fn(id) -> {id, 3} end)
    |> Map.new

    %GameState{
      players: players,
      buildings_built: buildings_built,
      coins: coins,
      buildings_available: %{
        wheat_field: 8,
        bakery: 8
      },
      turn: %GameTurn{
        player_id: List.first(player_ids),
        phase: :roll_dice
      }
    }
  end

  # only care about one die for now
  def roll_dice(game_state) do
    result = Enum.random(1..6)

    new_game_state = game_state
    |> update_turn(game_state.turn.player_id, :earn_income)

    {:die_roll, result, new_game_state}
  end

  def earn_income(game_state, die_roll) do
    building_activations = calc_building_activiations(game_state.buildings_built, game_state.turn.player_id, die_roll)

    new_game_state = game_state
    |> apply_building_activations(building_activations)
    |> update_turn(game_state.turn.player_id, :construction)

    {:earned_income, [], new_game_state}
  end

  def calc_building_activiations(buildings, current_player_id, die_roll) do
    [:wheat_field, :bakery]
    |> Enum.flat_map(fn(building) -> calc_building_activiations(buildings, current_player_id, die_roll, building) end)
    |> List.flatten
  end

  def apply_building_activations(game_state, []), do: game_state

  def apply_building_activations(game_state, building_activations) do
    [building_activation | remaining_activations] = building_activations
    new_game_state = pay_player(game_state, building_activation.to_player_id, building_activation.total_amount)

    apply_building_activations(new_game_state, remaining_activations)
  end

  # buildings

# figure out if the building is activated
  def calc_building_activiations(buildings, _current_player_id, 1, :wheat_field) do
    buildings
    |> Enum.map(fn({player_id, building_map}) -> activate_building(building_map, player_id, :wheat_field) end)
  end
  def calc_building_activiations(_, _, _, :wheat_field), do: []

  def calc_building_activiations(buildings, current_player_id, die_roll, :bakery) when die_roll >= 2 and die_roll <= 3 do
    activate_building(buildings[current_player_id], current_player_id, :bakery)
  end
  def calc_building_activiations(_, _, _, :bakery), do: []

# figure out the amount (if any)
  def activate_building(%{wheat_field: count}, player_id, :wheat_field) when count > 0 do
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

  def activate_building(%{bakery: count}, player_id, :bakery) when count > 0 do
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


  # utility methods

  def pay_player(game_state, player_id, amount) do
    %GameState{game_state | coins: %{
      game_state.coins | player_id => game_state.coins[player_id] + amount
    }}
  end

  def update_turn(game_state, player_id, phase) do
    %GameState{game_state | turn: %GameTurn{
      player_id: player_id,
      phase: phase
    }}
  end
end