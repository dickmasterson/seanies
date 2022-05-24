defmodule RarityWeb.Router do
  use RarityWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", RarityWeb do
    pipe_through :api

    get("/rarity", ApiController, :get_all)
    get("/rarity/:name", ApiController, :get_one)
  end
end
