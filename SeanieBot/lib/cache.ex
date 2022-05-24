defmodule Seanies.Cache do
  alias Seanies.Rarity

  @table_name :seanies_cache

  def get_all, do: :ets.tab2list(@table_name)

  def setup_table do
    :ets.new(@table_name, [:named_table, :public, :set])

    directory = metaplex_mints()
    populate_cache(directory)
  end

  def metaplex_mints, do: Application.get_env(:seanies, :metaplex_mints)

  def populate_cache(directory) do
    directory
    |> File.ls!()
    |> Enum.map(fn f ->
      directory
      |> Path.join(f)
      |> get_metadata()
      |> then(fn d -> :ets.insert(@table_name, d) end)
    end)

    Rarity.get_all_rarities()
    |> Enum.map(fn {name, rarity} -> :ets.update_element(@table_name, name, {4, rarity}) end)
  end

  def get_rarities do
    HTTPoison.get!("https://api.howrare.is/v0.1/collections/seanies/only_rarity")
    |> Map.get(:body)
    |> Jason.decode!()
    |> then(& &1["result"]["data"]["items"])
    |> Enum.map(&{&1["mint"], &1["rank"]})
    |> Enum.into(%{})
  end

  def get_metadata(filename) do
    json =
      filename
      |> File.read!()
      |> Jason.decode!()

    mint = filename |> Path.basename() |> String.replace(".json", "")
    name = json["name"]
    {name, json, mint, nil}
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
