defmodule DiceTownWeb.PageController do
  use DiceTownWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
