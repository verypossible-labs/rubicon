defmodule BorneolApiTest do
  use ExUnit.Case
  doctest BorneolApi

  test "greets the world" do
    assert BorneolApi.hello() == :world
  end
end
