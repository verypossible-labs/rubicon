defmodule HIDKeyboardNewLineFramingTest do
  use ExUnit.Case

  import Rubicon.Barcode.Framing.HIDKeyboardNewLineFraming, only: [init: 0, decode: 2]

  test "ignore null" do
    state = init()
    assert decode(state, <<0, 0, 0, 0, 0, 0, 0, 0>>) == {:none, state}
  end

  test "decode normal" do
    state = init()
    {:none, state} = decode(state, <<0, 0, 0x04, 0, 0, 0, 0, 0>>)
    {:none, state} = decode(state, <<0, 0, 0x05, 0, 0, 0, 0, 0>>)
    {:ok, barcode, state} = decode(state, <<0, 0, 0x28, 0, 0, 0, 0, 0>>)
    assert barcode == "ab"
    assert state == init()
  end

  test "decode shifted" do
    state = init()
    {:none, state} = decode(state, <<0x02, 0, 0x04, 0, 0, 0, 0, 0>>)
    {:none, state} = decode(state, <<0x20, 0, 0x05, 0, 0, 0, 0, 0>>)
    {:ok, barcode, state} = decode(state, <<0, 0, 0x28, 0, 0, 0, 0, 0>>)
    assert barcode == "AB"
    assert state == init()
  end

  test "decode with carriage return" do
    state = init()
    {:none, state} = decode(state, <<0x02, 0, 0x04, 0, 0, 0, 0, 0>>)
    {:none, state} = decode(state, <<0x20, 0, 0x05, 0, 0, 0, 0, 0>>)
    {:none, state} = decode(state, <<0x01, 0, 0x0D, 0, 0, 0, 0, 0>>)
    {:ok, barcode, state} = decode(state, <<0, 0, 0x28, 0, 0, 0, 0, 0>>)
    assert barcode == "AB"
    assert state == init()
  end
end
