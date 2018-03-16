defmodule DiceTown.Game.GameState do
  alias __MODULE__

  defstruct players: [], buildings_built: %{}, buildings_available: %{}, coins: %{}, turn: nil

  defmodule Player do
    defstruct id: nil, name: nil
  end

  defmodule GameTurn do
    defstruct player_id: nil, phase: nil
  end

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

  # accessor functions

  def get_player_coins(game_state, player_id) do
    game_state.coins[player_id]
  end

  def get_next_player(game_state) do
    current_player_id = game_state.turn.player_id
    player_ids = game_state.players
    |> Enum.map( fn(%Player{id: id}) -> id end)

    cond do
      current_player_id == List.last(player_ids) ->
        # loop to the first player
        List.first(player_ids)
      true ->
        # go to the next player
        _next_player(player_ids, current_player_id)
    end
  end

  # recursion is fun?
  defp _next_player([player_id | [next | _] ], player_id), do: next
  defp _next_player([_ | rest], player_id) do
    _next_player(rest, player_id)
  end

  # mutation functions

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

  def build_building(game_state, player_id, building) do
    %GameState{game_state | buildings_built: %{game_state.buildings_built |
      player_id => %{game_state.buildings_built[player_id] |
        building => game_state.buildings_built[player_id][building] + 1
      }
    }}
  end
end