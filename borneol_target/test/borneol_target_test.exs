defmodule BorneolTestTest do
  use ExUnit.Case
  doctest BorneolTarget

  test "greets the world" do
    assert BorneolTarget.hello() == :world
  end

  test "this is broken" do
    true = false
  end
end
