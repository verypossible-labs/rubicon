defmodule RubiconApiTest do
  use ExUnit.Case
  doctest RubiconApi

  test "greets the world" do
    assert RubiconApi.hello() == :world
  end
end
