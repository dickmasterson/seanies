defmodule Seanies do
  @moduledoc """
  Application entrypoint for `Seanies`.
  """

  use Application

  def start(_type, _args) do
    Seanies.Cache.setup_table()

    children = [
      Seanies.Consumer,
      Seanies.Solana,
      Seanies.Culler
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Seanies.Supervisor)
  end
end
