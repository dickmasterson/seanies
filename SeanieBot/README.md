# Seanies

Seanie Bot is a Discord bot for interacting with Seanies.

Commands are as follows:

```
/display - Display a Seanie by its name
/show-owned - Show all Seanies owned by a wallet
/beg - Beg for free Seanies if you have an empty wallet
/show-beggars - List all beggars
```

The `show-owned` relies on a Solana RPC call to determine which Seanies are owned by a given wallet address.

The `display` command relies on having all of the mint data and associated metadata json files on disk to avoid making unnecessary network calls.

The `beg` and `show-beggars` writes to and reads from a json file because setting up a postgres instance would be way overkill for what is essentially joke functionality.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `seanies` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:seanies, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/seanies>.

