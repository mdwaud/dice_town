defmodule DiceTown.Game.Player do
  use GenServer

  defmodule PlayerState do
    defstruct buildings: %{}, coins: %{}
  end

  @initial_buildings %{wheat_field: 1, bakery: 1}
  @initial_coins 3
  @building_costs %{
    wheat_field: 1,
    bakery: 1,
    cafe: 2
  }

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

  def pay(player, amount) do
    GenServer.call(player, {:pay, amount})
  end

  def earn_income(player, building, roll, is_current_player) do
    GenServer.call(player, {:earn_income, building, roll, is_current_player})
    #{:from_bank}
    #{:from_current_player}
    #{:from_all_players}
    #{:from_any_player}
  end

  def build(player, building) do
    GenServer.call(player, {:build, building})
  end

  # server

  def init(opts) do
    player_state = %PlayerState{
      buildings: opts[:buildings] || @initial_buildings,
      coins: opts[:coins] || @initial_coins
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

  def handle_call({:pay, amount}, _from, player_state) do
    new_amount = player_state.coins + amount
    {:reply, new_amount, %PlayerState{player_state| coins: new_amount}}
  end

  def handle_call({:build, building}, _from, player_state) do
    coins = player_state.coins
    case @building_costs[building] do
      nil ->
        {:reply, :unrecognized_building, player_state}
      amount when amount <= coins ->
        {:reply, :ok, do_build(player_state, building)}
      _ ->
        {:reply, :insufficient_coins, player_state}
    end
  end

  # utility methods

  defp do_build(player_state, building) do
    current_building_count = Map.get(player_state.buildings, building, 0)
    new_buildings_map = Map.merge(%{building => current_building_count + 1}, player_state.buildings)
    %PlayerState{player_state |
      buildings: new_buildings_map,
      coins: player_state.coins - @building_costs[building]
    }
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

  defp building_activation(buildings, :bakery, die_roll, true) when die_roll == 2 or die_roll == 3 do
    case buildings[:bakery] do
      0 ->
        nil
      count ->
        {:from_bank, count}
    end
  end

  defp building_activation(buildings, :cafe, 3, false) do
    case buildings[:cafe] do
      0 ->
        nil
      count ->
        {:from_current_player, count}
    end
  end

  defp building_activation(buildings, _, _, _is_current_player) do
    nil
  end
end