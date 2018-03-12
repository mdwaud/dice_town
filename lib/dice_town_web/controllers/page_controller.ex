defmodule DiceTownWeb.PageController do
  use DiceTownWeb, :controller

  alias DiceTown.GameServer

  def index(conn, _params) do
    # for now, let's just immediately start a one player game
    player_names = ["Player 1"]

    {:ok, pid} = GameServer.start_link(player_names)
IO.puts "PID"
IO.inspect pid

    value = GameServer.get_state(pid)
IO.puts "Game State"
IO.inspect value

    render conn, "index.html"
  end
end
