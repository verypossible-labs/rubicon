defmodule Rubicon.Barcode.SymbolFraming do
  @behaviour Rubicon.Barcode.Framing

  require Logger

  def decode(<<len, _::3-bytes, data::binary>>) do
    barcode_len = len - 7
    <<barcode::size(barcode_len)-bytes, _::binary>> = data
    {:ok, barcode}
  end

  def decode(frame) do
    {:error, {:invalid_barcode_frame, frame}}
  end
end
