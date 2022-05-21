defmodule SeaniesTest do
  use ExUnit.Case
  doctest Seanies

  test "greets the world" do
    assert Seanies.hello() == :world
  end
end
