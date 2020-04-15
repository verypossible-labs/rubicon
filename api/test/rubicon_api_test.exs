defmodule RubiconAPITest do
  use ExUnit.Case
  doctest RubiconAPI

  test "greets the world" do
    assert RubiconAPI.hello() == :world
  end
end
