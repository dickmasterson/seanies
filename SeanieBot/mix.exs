defmodule Seanies.MixProject do
  use Mix.Project

  def project do
    [
      app: :seanies,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Seanies, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:solana, "~> 0.2"},
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git"},
      {:jason, "~> 1.2"},
      {:httpoison, "~> 1.7"},
      {:gun, "2.0.1", hex: :remedy_gun, override: true}
    ]
  end
end
