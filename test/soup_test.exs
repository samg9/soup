defmodule SoupTest do
  use ExUnit.Case
  doctest Soup

  test "greets the world" do
    assert Soup.hello() == :world
  end
end
