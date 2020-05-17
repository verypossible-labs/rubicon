defmodule Rubicon.Barcode.Framing.HIDKeyboardNewLineFraming do
  @moduledoc """
  Decode HIDRaw messages as keyboard events.

  As most barcode scanners emulate keyboards, this decoder is set up
  to decode the USB HID scan codes being sent from a specific barcode scanner.
  This decoder requires that barcode scanner is configured to append
  a \n or \r\n pair after the actual barcode.

  Once a \n is discovered, a barcode is returned, with the \n removed.
  Additionally, all \r characters are automatically filtered.
  If the maximum line length is exceeded, then the buffer is reset.

  This module expects HID messages as a binary of 8 bytes:
  1. modifier keys
  2. reserved
  3. keypress #1
  4. keypress #2
  5. keypress #3
  6. keypress #4
  7. keypress #5
  See this doc for more details https://wiki.osdev.org/USB_Human_Interface_Devices

  ## Limitations
  This module does not do full decoding, just the keys relevant to extracting an
  alphanumeric + symbol barcode. As such, most control characters (e.g. ENTER, ESC, etc.)
  are ignored.
  Only keypress #1 is decoded.
  """

  @behaviour Rubicon.Barcode.Framing

  @max_length 1024

  require Logger

  @doc """
  Map a USB HID scan code to a tuple of normal, shifted, ctrl'd character options.
  Based on https://gist.github.com/MightyPork/6da26e382a7ad91b5496ee55fdc73db2
  """
  @usb_hid_keys %{
    0x04 => {"a", "A", nil},
    0x05 => {"b", "B", nil},
    0x06 => {"c", "C", nil},
    0x07 => {"d", "D", nil},
    0x08 => {"e", "E", nil},
    0x09 => {"f", "F", nil},
    0x0A => {"g", "G", nil},
    0x0B => {"h", "H", nil},
    0x0C => {"i", "I", nil},
    0x0D => {"j", "J", "\r"},
    0x0E => {"k", "K", nil},
    0x0F => {"l", "L", nil},
    0x10 => {"m", "M", nil},
    0x11 => {"n", "N", nil},
    0x12 => {"o", "O", nil},
    0x13 => {"p", "P", nil},
    0x14 => {"q", "Q", nil},
    0x15 => {"r", "R", nil},
    0x16 => {"s", "S", nil},
    0x17 => {"t", "T", nil},
    0x18 => {"u", "U", nil},
    0x19 => {"v", "V", nil},
    0x1A => {"w", "W", nil},
    0x1B => {"x", "X", nil},
    0x1C => {"y", "Y", nil},
    0x1D => {"z", "Z", nil},
    0x1E => {"1", "!", nil},
    0x1F => {"2", "@", nil},
    0x20 => {"3", "#", nil},
    0x21 => {"4", "$", nil},
    0x22 => {"5", "%", nil},
    0x23 => {"6", "^", nil},
    0x24 => {"7", "&", nil},
    0x25 => {"8", "*", nil},
    0x26 => {"9", "(", nil},
    0x27 => {"0", ")", nil},
    0x28 => {"\n", nil, nil},
    0x2C => {" ", " ", nil},
    0x2D => {"-", "_", nil},
    0x2E => {"=", "+", nil},
    0x2F => {"[", "{", nil},
    0x30 => {"]", "}", nil},
    0x31 => {"\\", "|", nil},
    0x32 => {"#", "~", nil},
    0x33 => {";", ":", nil},
    0x34 => {"'", "\"", nil},
    0x35 => {"`", "~", nil},
    0x36 => {",", "<", nil},
    0x37 => {".", ">", nil},
    0x38 => {"/", "?", nil}
  }

  @modifier_none 0x00
  @modifier_lctrl 0x01
  @modifier_lshift 0x02
  @modifier_rctrl 0x10
  @modifier_rshift 0x20

  def init do
    ""
  end

  def decode(decoded, <<0, 0, 0, 0, 0, 0, 0, 0>>) do
    {:none, decoded}
  end

  def decode(decoded, <<modifier_mask, _, code, _, _, _, _, _>>) do
    modifier = decode_modifier(modifier_mask)
    char_opts = Map.get(@usb_hid_keys, code)

    ch =
      case {modifier, char_opts} do
        {:none, {c, _, _}} -> c
        {:shift, {_, c, _}} -> c
        {:control, {_, _, c}} -> c
        _ -> nil
      end

    case ch do
      nil ->
        {:none, decoded}

      "\r" ->
        {:none, decoded}

      "\n" ->
        {:ok, decoded, init()}

      _ ->
        if String.length(decoded) < @max_length do
          {:none, decoded <> ch}
        else
          {:none, init()}
        end
    end
  end

  def decode(_decoded, msg) do
    {:error, {:invalid_barcode_frame, msg}, init()}
  end

  defp decode_modifier(mask) do
    case mask do
      @modifier_none -> :none
      @modifier_lshift -> :shift
      @modifier_rshift -> :shift
      @modifier_lctrl -> :control
      @modifier_rctrl -> :control
      _ -> :invalid
    end
  end
end
