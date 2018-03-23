defmodule DiceTownWeb.PageControllerTest do
  use DiceTownWeb.ConnCase

  @tag :skip
  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Dice Town"
  end
end
