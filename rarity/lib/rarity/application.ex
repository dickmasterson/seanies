defmodule Rarity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Rarity.Cache.setup_table()

    children = [
      RarityWeb.Telemetry,
      {Phoenix.PubSub, name: Rarity.PubSub},
      RarityWeb.Endpoint
    ]
    opts = [strategy: :one_for_one, name: Rarity.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RarityWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
