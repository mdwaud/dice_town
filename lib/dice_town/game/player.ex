defmodule DiceTown.Game.Player do
  use GenServer

  defmodule PlayerState do
    defstruct buildings: %{}, coins: %{}
  end

  @initial_buildings %{wheat_field: 1, bakery: 1}
  @initial_coins 3

  # client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def get_state(player) do
    GenServer.call(player, :get_state)
  end

  def roll_dice do
    Enum.random(1..6)
  end

  def earn_income(player, building, roll, is_current_player) do
    GenServer.call(player, {:earn_income, building, roll, is_current_player})
    #{:from_bank}
    #{:from_current_player}
    #{:from_all_players}
    #{:from_any_player}
  end

  # server

  def init(opts) do
    player_state = %PlayerState{
      buildings: opts[:buildings] || @initial_buildings,
      coins: @initial_coins
    }
    {:ok, player_state}
  end

#  def init(opts = %{}) do
#    player_state = %PlayerState{
#      buildings: opts[:buildings} || %{},
#      coins: opts[:buildings} || %{}
#    }
#    {:ok, player_state}
#  end

  def handle_call(:get_state, _from, player_state) do
    {:reply, player_state, player_state}
  end

  def handle_call({:earn_income, building, die_roll, is_current_player}, _from, player_state) do
    result = building_activation(player_state.buildings, building, die_roll, is_current_player)
    {:reply, result, player_state}
  end

  # building specific logic

  defp building_activation(buildings, :wheat_field, 1, _is_current_player) do
    case buildings[:wheat_field] do
      0 ->
        nil
      count ->
        {:from_bank, count}
    end
  end
end