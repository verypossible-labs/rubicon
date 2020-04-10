defmodule RubiconHostTest do
  use ExUnit.Case
  doctest RubiconHost

  test "greets the world" do
    assert RubiconHost.hello() == :world
  end
end
