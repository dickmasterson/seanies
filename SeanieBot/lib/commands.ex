defmodule Seanies.Commands do
  alias Seanies.Cache
  alias Seanies.Solana, as: SolanaApi

  alias Nostrum.Struct.Embed
  import Embed

  require Logger

  @beggars_file "./beggars.json"

  opt = fn type, name, desc, opts ->
    %{type: type, name: name, description: desc}
    |> Map.merge(Enum.into(opts, %{}))
  end

  @display_opts [
    opt.(3, "name", "Seanie name or sequence number", required: true)
  ]

  @show_owned_opts [
    opt.(3, "wallet", "Wallet address to check for ownership", required: true)
  ]

  @beg_opts [
    opt.(3, "wallet", "Wallet address (must be empty)", required: true),
    opt.(3, "reason", "Why did you miss the mint? Do you deserve a free Seanie?", required: true)
  ]

  @commands %{
    "display" => {:display, "Display a Seanie by its number or name", @display_opts},
    "show-owned" => {:show_owned, "Show all owned Seanies by wallet", @show_owned_opts},
    "beg" => {:beg, "Beg for Seanies if you missed the mint", @beg_opts},
    "show-beggars" => {:show_beggars, "Feeling generous? Get a list of Seanie-less plebs", []}
  }

  def commands, do: @commands

  def dispatch(%{data: %{name: cmd}} = interaction) do
    case Map.get(@commands, cmd) do
      {function, _, _} -> :erlang.apply(__MODULE__, function, [interaction])
      nil -> nil
    end
  end

  def display(%{data: %{options: [%{value: name}]}} = _interaction) do
    name =
      case Integer.parse(name) do
        {val, _} -> "Seanies \##{val}"
        :error -> name
      end

    {address, meta, rarity} = Cache.get_by_name(name)

    if meta do
      %Embed{}
      |> put_color(0xAA00FF)
      |> put_title(name)
      |> put_image(meta["image"])
      |> put_author(
        "Seanies.art",
        "https://seanies.art",
        "https://seanies.art/wp-content/uploads/sites/18/2022/04/cropped-Seanies_Logo-300x114.png"
      )
      |> put_description("**Rank #{rarity}** - #{meta["description"]}")
      |> put_url("https://solscan.io/token/#{address}")
      |> put_thumbnail("https://i.imgur.com/RiYh1nd.png")
      |> then(fn embed ->
        Enum.reduce(meta["attributes"], embed, fn attr, embed ->
          put_field(embed, attr["trait_type"], attr["value"], true)
        end)
      end)
      |> then(fn embed -> {:embed, embed} end)
    else
      {:msg, "No Seanies found by that name."}
    end
  rescue
    _ -> {:msg, "Error occurred, sorry."}
  end

  def show_owned(%{data: %{options: [%{value: account}]}} = _interaction) do
    with {:ok, bin_addr} <- B58.decode58(account),
         {:ok, _addr} <- Solana.Key.check(bin_addr),
         [_val | _rest] = tokens <- get_tokens_owned_by_account(account) do
      embeds =
        tokens
        |> Enum.chunk_every(25)
        |> Enum.map(fn chunk ->
          Enum.reduce(chunk, %Embed{color: 0xAA00FF}, fn {_, name, _, rarity}, embed ->
            put_field(embed, name, "*Rank* **#{rarity}**", true)
          end)
        end)

      [first | rest] = embeds

      first =
        first
        |> put_description("Total owned: #{length(tokens)}")
        |> put_author(
          "Seanies.art",
          "https://seanies.art",
          "https://seanies.art/wp-content/uploads/sites/18/2022/04/cropped-Seanies_Logo-300x114.png"
        )
        |> put_thumbnail("https://i.imgur.com/RiYh1nd.png")

      {:embeds, [first | rest]}
    else
      {:error, _} -> {:msg, "That's definitely not a valid wallet address. Try harder next time."}
      [] -> {:msg, "No Seanies found in this account."}
    end
  rescue
    _ -> {:msg, "Error occurred, sorry."}
  end

  def beg(%{user: %{id: user_id}, data: %{options: [%{value: wallet}, %{value: reason}]}}) do
    File.exists?(@beggars_file) || File.write!(@beggars_file, "{}")

    with {:ok, bin_addr} <- B58.decode58(wallet),
         {:ok, _addr} <- Solana.Key.check(bin_addr),
         [] <- get_tokens_owned_by_account(wallet) do
      beggars =
        read_beggars_file()
        |> Map.put(wallet, %{user_id: user_id, reason: reason})
        |> Jason.encode_to_iodata!()

      File.write!(@beggars_file, beggars)

      {:msg, "You've been added to the beggars list."}
    else
      {:error, _} -> {:msg, "That's definitely not a valid wallet address. Try harder next time."}
      [_seanie | _rest] -> {:msg, "You can't beg for Seanies if you already have some, greedy."}
    end
  end

  def show_beggars(_interaction) do
    with {:ok, contents} <- File.read(@beggars_file),
         {:ok, json} <- Jason.decode(contents),
         num when num > 0 <- Enum.count(json) do
      msg =
        Enum.map_join(json, "\n", fn {wallet, %{"user_id" => user_id, "reason" => reason}} ->
          "<@!#{user_id}> - Address `#{wallet}` - \"#{reason}\""
        end)

      {:eph_msg, msg}
    else
      _ -> {:eph_msg, "No beggars to show."}
    end
  end

  def read_beggars_file do
    @beggars_file
    |> File.read!()
    |> Jason.decode!()
  end

  def remove_beggars([]), do: :noop

  def remove_beggars(wallets) do
    Logger.debug("Culling beggars: #{inspect(wallets)}")

    beggars =
      read_beggars_file()
      |> Map.drop(wallets)
      |> Jason.encode_to_iodata!()

    File.write!(@beggars_file, beggars)
  end

  def get_owner_of_token(token) do
    {"getTokenLargestAccounts", [token, %{}]}
    |> SolanaApi.make_request()
  end

  def get_tokens_owned_by_account(account) do
    program_id = Application.get_env(:seanies, :program_id)

    {"getTokenAccountsByOwner", [account, %{programId: program_id}, %{encoding: "jsonParsed"}]}
    |> SolanaApi.make_request()
    |> elem(1)
    |> Stream.filter(fn map ->
      map["account"]["data"]["parsed"]["info"]["tokenAmount"]["amount"] == "1"
    end)
    |> Stream.map(fn map -> map["account"]["data"]["parsed"]["info"]["mint"] end)
    |> Stream.map(fn mint -> {mint, Cache.get_by_address(mint)} end)
    |> Stream.map(fn {mint, {name, meta, rarity}} -> {mint, name, meta, rarity} end)
    |> Enum.reject(fn {_mint, name, _url, _rarity} -> is_nil(name) end)
  end
end
