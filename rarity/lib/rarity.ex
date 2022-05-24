defmodule Rarity do
  @moduledoc """
  Rarity algorithm logic
  """

  alias Rarity.Cache

  @trait_types ~w(Body Extras Eyes Face Head Items Mouth Sean)
  @num_seanies 5_000

  @trait_themes [
    MapSet.new(["Civil War Beard", "Civil War Rifle", "Civil War Glasses", "Civl War Glasses", "Union Soldier Hat", "Union Soldier Outfit"]),
    MapSet.new(["Straw", "Ass Farming Stuff", "Farmer Hat", "Farmer Outfit"]),
    MapSet.new(["Dildo", "EGirl Lewk", "Cat Headphones"]),
    MapSet.new(["Snek Flag", "Tie Dye Shirt", "Joint", "Rasta Hat", "High Eyes"]),
    MapSet.new(["Snek Flag", "Drugs Shirt", "Dick Facial Hair", "Dick Hair", "Nerf Dart Eye", "Bad Zinger Tomato"]),
    MapSet.new(["Mask", "Vaxx Needle"]),
    MapSet.new(["Black V Neck", "Headphones", "Twitch", "Sean Hair", "Diet Coke", "Base"]),
    MapSet.new(["Data Shirt", "Data Eyes"])
  ]

  def create_distributions do
    seanies =
      Cache.get_all()
      |> Enum.map(fn {name, %{"attributes" => attrs}, _, _} -> {name, attributes_to_map(attrs)} end)
      |> Enum.into(%{})

    num_traits_d = num_traits_dist(seanies)
    grouped_traits_d = grouped_traits_dist(seanies)

    {seanies, num_traits_d, grouped_traits_d}
  end

  def get_all_rarities do
    {seanies, num_traits_d, grouped_traits_d} = create_distributions()

    seanies
    |> Enum.map(&get_score(&1, num_traits_d, grouped_traits_d))
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> Enum.with_index(1)
    |> Enum.map(fn {{name, _score}, index} -> {name, index} end)
    |> Enum.into(%{})
  end

  def get_score({name, traits}, num_traits_d, grouped_traits_d) do
    gs = golden_score(name)
    ts = theme_score(traits)
    nt = num_traits_score(traits, num_traits_d)
    gt = grouped_traits_score(traits, grouped_traits_d)

    {name, nt * (gt + ts) + gs}
  end

  def num_traits_score(traits, distribution) do
    num_traits = Enum.count(traits)
    occurrences = distribution[num_traits]
    :math.log10(@num_seanies / occurrences) |> max(1)
  end

  def grouped_traits_score(traits, distribution) do
    Enum.reduce(@trait_types, 0, fn type, score ->
      occurrences = distribution[type][traits[type] || :empty]
      score + :math.log10(@num_seanies / occurrences)
    end)
  end

  def golden_score(name) do
    Regex.match?(~r/Seanies #\d/, name) && 0 || 10
  end

  def theme_score(traits) do
    trait_set =
      traits
      |> Map.values()
      |> MapSet.new()

    Enum.reduce(@trait_themes, 0, fn theme_set, score ->
      size = MapSet.intersection(theme_set, trait_set) |> MapSet.size()
      score + max(0, size - 1)
    end)
  end

  def attributes_to_map(attributes) do
    attributes
    |> Enum.map(fn a -> {a["trait_type"], a["value"]} end)
    |> Enum.into(%{})
  end

  def num_traits_dist(seanies) do
    Enum.reduce(seanies, %{}, fn {_n, t}, m ->
      num = Enum.count(t)
      count = m[num] || 0
      Map.put(m, num, count + 1)
    end)
  end

  def grouped_traits_dist(seanies) do
    Enum.reduce(seanies, %{}, fn {_n, t}, m ->
      Enum.reduce(@trait_types, m, fn type, acc ->
        bucket = acc[type] || %{}
        trait = t[type] || :empty
        count = bucket[trait] || 0
        bucket = Map.put(bucket, trait, count + 1)
        Map.put(acc, type, bucket)
      end)
    end)
  end

end
