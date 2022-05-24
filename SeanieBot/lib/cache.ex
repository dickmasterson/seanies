defmodule Seanies.Cache do
  @table_name :seanies_cache

  def get_all, do: :ets.tab2list(@table_name)

  def setup_table do
    :ets.new(@table_name, [:named_table, :public, :set])
    populate_cache()
  end

  def populate_cache() do
    HTTPoison.get!("https://seanies.brandthill.com/api/rarity")
    |> Map.get(:body)
    |> Jason.decode!()
    |> then(& &1["data"])
    |> Enum.map(fn map -> {map["name"], map["metadata"], map["mint"], map["rarity"]} end)
    |> Enum.map(&:ets.insert(@table_name, &1))
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
