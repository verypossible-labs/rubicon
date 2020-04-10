defmodule RubiconTestTest do
  use ExUnit.Case
  doctest RubiconTarget

  test "greets the world" do
    assert RubiconTarget.hello() == :world
  end

  test "this is broken" do
    true = false
  end
end
