defmodule RarityWeb.ApiView do
  use RarityWeb, :view

  def render("list.json", %{list: list}) do
    %{
      data: render_many(list, __MODULE__, "seanie.json", as: :seanie)
    }
  end

  def render("one.json", %{seanie: seanie}) do
    %{
      data: render_one(seanie, __MODULE__, "seanie.json", as: :seanie)
    }
  end

  def render("empty.json", %{name: name}) do
    %{
      error: "Not Found",
      name: name
    }
  end

  def render("seanie.json", %{seanie: seanie}) do
    {name, metadata, mint, rarity} = seanie

    %{
      name: name,
      metadata: metadata,
      mint: mint,
      rarity: rarity
    }
  end
end
