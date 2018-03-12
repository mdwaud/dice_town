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

  # game logic

  def init_game_state(player_names) do
    players = player_names
    |> Enum.with_index
    |> Enum.map( fn({name, index}) -> %Player{id: index, name: name} end )

    player_ids = players
    |> Enum.map( fn(%Player{id: id}) -> id end)

    buildings_built = player_ids
    |> Enum.map( fn(id) -> {id, %{wheat_field: 1, ranch: 1}} end)
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
        ranch: 8
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
    new_game_state = game_state
    |> wheat_field(die_roll)
    |> update_turn(game_state.turn.player_id, :construction)

    {:earned_income, [], new_game_state}
  end

  def wheat_field(game_state, 1) do
    player_ids = game_state.players
    |> Enum.map( fn(%Player{id: id}) -> id end)

    pay_players(game_state, player_ids, 1)
  end
  def wheat_field(game_state, _), do: game_state

  # utility methods
  def pay_players(game_state, [], _), do: game_state
  def pay_players(game_state, player_ids, amount) do
    [player_id | other_player_ids] = player_ids

    new_game_state = pay_player(game_state, player_id, amount)

    pay_players(new_game_state, other_player_ids, amount)
  end

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