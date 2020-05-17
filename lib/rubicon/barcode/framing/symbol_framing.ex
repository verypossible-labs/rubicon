defmodule Rubicon.Barcode.Framing.SymbolFraming do
  @behaviour Rubicon.Barcode.Framing

  require Logger

  def init do
    nil
  end

  def decode(nil, <<len, _::3-bytes, data::binary>>) do
    barcode_len = len - 7
    <<barcode::size(barcode_len)-bytes, _::binary>> = data
    {:ok, barcode, nil}
  end

  def decode(nil, frame) do
    {:error, {:invalid_barcode_frame, frame}, nil}
  end
end
