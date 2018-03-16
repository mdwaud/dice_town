defmodule DiceTown.Game do
  alias DiceTown.Game.GameState
  alias DiceTown.Game.EarnIncome
  alias DiceTown.Game.Construction

  # game logic

  def init(player_names) do
    GameState.init_game_state(player_names)
  end

  # only care about one die for now
  def roll_dice(game_state, player_id) do
    die_roll = Enum.random(1..6)

    new_game_state = game_state
    |> GameState.update_turn(player_id, :earn_income)

    {:die_roll, %{player_id: player_id, die_roll: die_roll}, new_game_state}
  end

  def earn_income(game_state, player_id, die_roll) do
    building_activations = EarnIncome.calc_building_activiations(game_state.buildings_built, player_id, die_roll)
    {temp_game_state, earn_income_results} = game_state
    |> EarnIncome.apply_building_activations(building_activations)

    new_game_state = temp_game_state
    |> GameState.update_turn(player_id, :construction)

    {:earned_income, earn_income_results, new_game_state}
  end

  def build(game_state, player_id, building) do
    case Construction.build(game_state, player_id, building) do
      {:ok, built_game_state} ->
        # eventually check for victory conditions here
        next_player_id = GameState.get_next_player(built_game_state)
        new_game_state = built_game_state
        |> GameState.update_turn(next_player_id, :roll_dice)

        {:built, building, new_game_state}
      {:error, reason} ->
        {:error, reason}
    end
  end
end