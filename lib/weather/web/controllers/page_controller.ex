defmodule Weather.Web.PageController do
  use Weather.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
