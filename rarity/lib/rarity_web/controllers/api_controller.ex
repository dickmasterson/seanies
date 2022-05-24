defmodule RarityWeb.ApiController do
  use RarityWeb, :controller

  alias Rarity.Cache

  def get_all(conn, _params) do
    list =
      Cache.get_all()
      |> Enum.sort_by(&elem(&1, 3), :asc)

    conn
    |> put_status(200)
    |> render(:list, list: list)
  end

  def get_one(conn, params) do
    name = params["name"]

    case Cache.get_by_name(name) do
      nil ->
        conn
        |> put_status(404)
        |> render(:empty, name: name)

      seanie ->
        conn
        |> put_status(200)
        |> render(:one, seanie: seanie)
    end
  end
end
