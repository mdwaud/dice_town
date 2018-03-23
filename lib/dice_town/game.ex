defmodule DiceTown.Game do
  use GenServer

  alias DiceTown.Game.Player

  defmodule GameState do
    defstruct players: [], die_fn: nil, phase: nil, turn_player_id: nil, player_order: [], last_roll: nil
  end

  @building_activation_order [:cafe, :bakery, :wheat_field]

  # client

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def roll_dice(pid, player_id) do
    GenServer.call(pid, {:roll_dice, player_id})
  end

  def build(pid, player_id, building) do
    GenServer.call(pid, {:build, player_id, building})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  # server

  # new game
  def init(opts = %{player_order: player_order}) do
    die_fn = opts[:die_fn] || fn() -> Player.roll_dice() end

    players = player_order
    |> Enum.map(fn(player_id) -> {player_id, init_player(%{})} end)
    |> Map.new

    game_state = %GameState{
      players: players,
      die_fn: die_fn,
      phase: :roll_dice,
      turn_player_id: List.first(player_order),
      player_order: player_order
    }
    {:ok, game_state}
  end

  # from a save
  def init(opts = %{game_state: game_state_map}) do
    die_fn = opts[:die_fn] || fn() -> Player.roll_dice() end

    players = game_state_map[:player_order]
    |> Enum.map(fn(player_id) -> {player_id, init_player(game_state_map[:players][player_id])} end)
    |> Map.new

    game_state = %GameState{
      players: players,
      die_fn: die_fn,
      phase: game_state_map[:phase],
      turn_player_id: game_state_map[:turn_player_id],
      player_order: game_state_map[:player_order]
    }
    {:ok, game_state}
  end

  def handle_call(:get_state, _from, game_state) do
    {:reply, serialize_game_state(game_state), game_state}
  end

  def handle_call({:roll_dice, _player_id}, _from, game_state) do
    {new_game_state, actions} = {game_state, []}
    |> roll_dice
    |> earn_income
    |> advance_game(:construction, game_state.turn_player_id)
    # todo: notify all players

    {:reply, {serialize_game_state(new_game_state), actions}, new_game_state}
  end

  def handle_call({:build, player_id, building}, _from, game_state) do
    np = next_player(
      game_state.turn_player_id,
      game_state.player_order
    )
    {new_game_state, actions} = {game_state, []}
    |> build(building)
    |> advance_game(:roll_dice, np)

    {:reply, {serialize_game_state(new_game_state), actions}, new_game_state}
  end

  defp init_player(player_data) do
    {:ok, pid} = Player.start_link(%{
      buildings: player_data[:buildings],
      coins: player_data[:coins],
    })

    pid
  end

  # rolling_dice

  defp roll_dice({game_state, _actions}) do
    die_roll = game_state.die_fn.()
    {%GameState{game_state| last_roll: die_roll}, [{:die_roll, die_roll}]}
  end

  # earning income

  defp earn_income({game_state, actions}) do
    player_building_activation_order(game_state.player_order)
    |> handle_activations(game_state, actions)
  end

  # build up a list of {player_id, building}
  # ex: [{1, :cafe}, {0, :cafe}, {1, :bakery}, {0, :bakery}, {1, :wheat_field}, {0, wheat_field}]
  defp player_building_activation_order(player_order) do
    reverse_player_order = Enum.reverse(player_order)
    @building_activation_order
    |> Enum.flat_map(fn(building) ->
      Enum.map(reverse_player_order, fn(player_id) -> {player_id, building} end)
    end)
  end

  # run through the list of {player, building} and process each result of Player.earn_income
  defp handle_activations([], game_state, actions), do: {game_state, actions}
  defp handle_activations([{player_id, building}| tail], game_state, actions) do
    player = game_state.players[player_id]
    is_current_player = player_id == game_state.turn_player_id

    case Player.earn_income(player, building, game_state.last_roll, is_current_player) do
      nil ->
        handle_activations(tail, game_state, actions)
      {:from_bank, amount} ->
        Player.pay(player, amount)
        new_actions = actions ++ [{:earn_income, %{player_id: player_id, from: :bank, building: building, amount: amount}}]
        handle_activations(tail, game_state, new_actions)
      {:from_current_player, amount} ->
        current_player = game_state.players[game_state.turn_player_id]
        new_action = case Player.pay_player(current_player, player, amount) do
          :ok ->
            {:earn_income, %{player_id: player_id, from: {:player, game_state.turn_player_id}, building: building, amount: amount}}
          :insufficient_coins ->
            {:earn_income_miss, %{player_id: player_id, from: {:player, game_state.turn_player_id}, building: building, amount: 0}}
          {:partial_payment, amount} ->
            {:earn_income_partial, %{player_id: player_id, from: {:player, game_state.turn_player_id}, building: building, amount: amount}}
        end

        new_actions = actions ++ [new_action]
        handle_activations(tail, game_state, new_actions)
    end
  end

  # building

  defp build({game_state, actions}, nil) do
    {game_state, [{:construction, %{player_id: game_state.turn_player_id, building: nil}}]}
  end

  defp build({game_state, actions}, building) do
    new_action = case Player.build(game_state.players[game_state.turn_player_id], building) do
      :ok ->
        {:construction, %{player_id: game_state.turn_player_id, building: building}}
    end

    {game_state, actions ++ [new_action]}
  end

  # utility methods

  defp advance_game({game_state, actions}, phase, turn_player_id) do
    new_game_state = %{ game_state | phase: phase, turn_player_id: turn_player_id}
    {new_game_state, actions}
  end

  defp serialize_game_state(game_state) do
    players_map = game_state.players
    |> Enum.map(fn({id, player}) -> {id, serialize_player(Player.get_state(player))} end)
    |> Map.new
    %{
      players: players_map,
      phase: game_state.phase,
      turn_player_id: game_state.turn_player_id,
      player_order: game_state.player_order
    }
  end

  defp serialize_player(player_state) do
    %{
      buildings: player_state.buildings,
      coins: player_state.coins
    }
  end

  defp next_player(current_player_id, player_order) do
    if current_player_id == List.last(player_order) do
      List.first(player_order)
    else
      _next_player(current_player_id, player_order)
    end
  end
  # recursion is fun?
  defp _next_player(player_id, [player_id | [next | _] ]), do: next
  defp _next_player(player_id, [_ | rest] ) do
    _next_player(player_id, rest)
  end
end