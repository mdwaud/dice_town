defmodule DiceTown.Game do
  alias DiceTown.Game.EarnIncome

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

  defmodule EarnIncomeResult do
    defstruct building_activation: nil, success: nil
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
        bakery: 8,
        cafe: 8
      },
      turn: %GameTurn{
        player_id: List.first(player_ids),
        phase: :roll_dice
      }
    }
  end

  # only care about one die for now
  def roll_dice(game_state, _player_id) do
    result = Enum.random(1..6)

    new_game_state = game_state
    |> update_turn(game_state.turn.player_id, :earn_income)

    {:die_roll, result, new_game_state}
  end

  def earn_income(game_state, _player_id, die_roll) do
    building_activations = EarnIncome.calc_building_activiations(game_state.buildings_built, game_state.turn.player_id, die_roll)
    {temp_game_state, earn_income_results} = game_state
    |> EarnIncome.apply_building_activations(building_activations)

    new_game_state = temp_game_state
    |> update_turn(game_state.turn.player_id, :construction)

    {:earned_income, earn_income_results, new_game_state}
  end


  # utility methods

  def update_turn(game_state, player_id, phase) do
    %GameState{game_state | turn: %GameTurn{
      player_id: player_id,
      phase: phase
    }}
  end
end