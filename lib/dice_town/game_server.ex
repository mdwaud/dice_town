defmodule DiceTown.GameServer do
  use GenServer

  # state struct

  defmodule Player do
    defstruct id: nil, name: nil
  end

  defmodule GameState do
    defstruct players: [], buildings_built: %{}
  end

  @buildings [
    :wheat_field,
    :ranch
  ]

  # client

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def start_link(player_names) do
    GenServer.start_link(__MODULE__, player_names)
  end

  # server

  def init(player_names) do
    game_state = init_game_state(player_names)
    {:ok, game_state}
  end

  def handle_call(:get_state, _from, game_state) do
    {:reply, game_state, game_state}
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

    game_state = %GameState{
      players: players,
      buildings_built: buildings_built
    }
  end
end