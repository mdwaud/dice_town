defmodule DiceTown.GameServer do
  use GenServer

  alias DiceTown.Game

  # client

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def start_link(player_names) do
    GenServer.start_link(__MODULE__, player_names)
  end

  # server

  def init(player_names) do
    game_state = Game.init(player_names)
    {:ok, game_state}
  end

  def handle_call(:get_state, _from, game_state) do
    {:reply, game_state, game_state}
  end
end