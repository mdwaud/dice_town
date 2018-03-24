defmodule DiceTown.Game.Player do
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

  def init do
    %PlayerState{
      buildings: @initial_buildings,
      coins: @initial_coins,
    }
  end

  def init(opts) do
    %PlayerState{
      buildings: opts[:buildings] || @initial_buildings,
      coins: opts[:coins] || @initial_coins
    }
  end

  # client

  def roll_dice do
    Enum.random(1..6)
  end

  def pay(player_state, amount) do
    new_amount = player_state.coins + amount
    {:ok, %PlayerState{player_state| coins: new_amount}}
  end

  def pay_player(player, other_player, amount) do
    GenServer.call(player, {:pay_player, other_player, amount})
  end

  #{:from_bank}
  #{:from_current_player}
  #{:from_all_players}
  #{:from_any_player}
  def earn_income(player_state, building, die_roll, is_current_player) do
    building_activation(player_state.buildings, building, die_roll, is_current_player)
  end

  def build(player_state, building) do
    coins = player_state.coins
    case @building_costs[building] do
      nil ->
        {:unrecognized_building, player_state}
      amount when amount <= coins ->
        {:ok, do_build(player_state, building)}
      _ ->
        {:insufficient_coins, player_state}
    end
  end

  def serialize(player_state) do
    %{
      buildings: player_state.buildings,
      coins: player_state.coins
    }
  end


  # server

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

  def handle_call({:pay_player, other_player, amount}, _from, player_state) do
    cond do
      # no payment
      player_state.coins == 0 ->
        {:reply, :insufficient_coins, player_state}
      # full payment
      player_state.coins >= amount ->
        DiceTown.Game.Player.pay(other_player, amount)
        new_amount = player_state.coins - amount
        {:reply, :ok, %PlayerState{player_state| coins: new_amount}}
      # partial payment
      true ->
        DiceTown.Game.Player.pay(other_player, player_state.coins)
        {:reply, {:partial_payment, player_state.coins}, %PlayerState{player_state| coins: 0}}
    end
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
    case buildings[:wheat_field] || 0 do
      0 ->
        nil
      count ->
        {:from_bank, count}
    end
  end

  defp building_activation(buildings, :bakery, die_roll, true) when die_roll == 2 or die_roll == 3 do
    case buildings[:bakery] || 0 do
      0 ->
        nil
      count ->
        {:from_bank, count}
    end
  end

  defp building_activation(buildings, :cafe, 3, false) do
    case buildings[:cafe] || 0 do
      0 ->
        nil
      count ->
        {:from_current_player, count}
    end
  end

  defp building_activation(_buildings, _, _, _is_current_player) do
    nil
  end
end