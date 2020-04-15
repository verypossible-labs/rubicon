defmodule RubiconTest do
  use ExUnit.Case
  doctest Rubicon

  test "greets the world" do
    assert Rubicon.hello() == :world
  end
end
