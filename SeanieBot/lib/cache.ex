defmodule Seanies.Cache do
  @table_name :seanies_cache

  def setup_table do
    :ets.new(@table_name, [:named_table, :public, :set])

    directory = metaplex_mints()
    rarities = get_rarities()
    populate_cache(directory, rarities)
  end

  def metaplex_mints, do: Application.get_env(:seanies, :metaplex_mints)

  def populate_cache(directory, rarities) do
    directory
    |> File.ls!()
    |> Enum.map(fn f ->
      directory
      |> Path.join(f)
      |> get_metadata(rarities)
      |> then(fn d -> :ets.insert(@table_name, d) end)
    end)
  end

  def get_rarities do
    HTTPoison.get!("https://api.howrare.is/v0.1/collections/seanies/only_rarity")
    |> Map.get(:body)
    |> Jason.decode!()
    |> then(& &1["result"]["data"]["items"])
    |> Enum.map(&{&1["mint"], &1["rank"]})
    |> Enum.into(%{})
  end

  def get_metadata(filename, rarities) do
    json =
      filename
      |> File.read!()
      |> Jason.decode!()

    mint = filename |> Path.basename() |> String.replace(".json", "")
    {json["name"], json, mint, rarities[mint]}
  end

  def get_by_name(name) do
    case :ets.match(@table_name, {name, :"$2", :"$1", :"$3"}) do
      [] -> {nil, nil, nil}
      [[address, meta, rarity]] -> {address, meta, rarity}
    end
  end

  def get_by_address(address) do
    case :ets.match(@table_name, {:"$1", :"$2", address, :"$3"}) do
      [] -> {nil, nil, nil}
      [[name, meta, rarity]] -> {name, meta, rarity}
    end
  end
end
