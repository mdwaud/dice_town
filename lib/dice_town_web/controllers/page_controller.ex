defmodule DiceTownWeb.PageController do
  use DiceTownWeb, :controller

  alias DiceTown.GameServer

  def index(conn, _params) do
    # for now, let's just immediately start a one player game
    player_names = ["Player 1"]

    {:ok, pid} = GameServer.start_link(player_names)
    game_state = GameServer.get_state(pid)


    render conn, "index.html", %{game_state: game_state}
  end
end
