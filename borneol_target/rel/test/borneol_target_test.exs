defmodule BorneolTargetTest do
  use ExUnit.Case

  test "the truth" do
    assert 1 + 1 == 2
  end

  @tag fail: true
  test "GPIO pin is low" do
    {:ok, gpio} = Circuits.GPIO.open(16, :input)
    assert Circuits.GPIO.read(gpio) == 0
  end
end
