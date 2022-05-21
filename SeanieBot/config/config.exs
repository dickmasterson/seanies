import Config

config :nostrum,
  token: System.get_env("DISCORD_API_KEY")

config :seanies,
  metaplex_mints: "./metaplex/metadata",
  program_id: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
  rpc_endpoint: System.get_env("SOLANA_RPC_ENDPOINT")
