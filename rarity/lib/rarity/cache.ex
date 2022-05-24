defmodule Rarity.Cache do
  @table_name :seanies_cache

  def get_all, do: :ets.tab2list(@table_name)

  def setup_table do
    :ets.new(@table_name, [:named_table, :public, :set])

    directory = metaplex_dir()
    populate_cache(directory)
  end

  def metaplex_dir, do: Application.get_env(:rarity, :metaplex_metadata)

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
    case :ets.lookup(@table_name, name) do
      [] -> nil
      [item] -> item
    end
  end
end
