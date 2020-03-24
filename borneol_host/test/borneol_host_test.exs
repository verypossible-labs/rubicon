defmodule BorneolHostTest do
  use ExUnit.Case
  doctest BorneolHost

  test "greets the world" do
    assert BorneolHost.hello() == :world
  end
end
