import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rarity, RarityWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cYpPqVe6MNwrQE3fhh77X96Gwcw5IiYY+03ltez6LLDgKT1QlNvl8XHqwAg01ISw",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
