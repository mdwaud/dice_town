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

    new_game_state = %GameState{game_state | turn: %GameTurn{
      player_id: game_state.turn.player_id,
      phase: :earn_income
    }}

    {:die_roll, result, new_game_state}
  end
end