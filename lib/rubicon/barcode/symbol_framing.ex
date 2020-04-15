defmodule Rubicon.Barcode.SymbolFraming do
  @behaviour Rubicon.Barcode.Framing

  require Logger

  @code_128_codes [10, 13, 24]

  def decode(<<len, _ :: 3-bytes, data :: binary>> = report) do
    # Subtract 7 bytes from the data to unwrap
    Logger.debug "BarcodeData: #{inspect report}"
    barcode_len = len - 7
    barcode_type = determine_barcode_type(barcode_len, data)
    <<barcode :: size(barcode_len)-bytes, _ :: binary>> = data
    do_decode(barcode_type, barcode)
  end

  def decode(frame) do
    {:error, {:invalid_barcode_frame, frame}}
  end

  defp do_decode(:ucc_ean, data) do
    barcode = :binary.replace(data, <<29>>, <<>>)
    {:ok, barcode}
  end

  defp do_decode(:code_128, barcode) do
    {:ok, barcode}
  end

  defp do_decode(:string, barcode) do
    {:ok, barcode}
  end

  defp determine_barcode_type(len, data) do
    case data do
      <<_ :: size(len)-bytes, 0, 37, _ :: binary>> ->
        :ucc_ean

      <<_ :: size(len)-bytes, 0, code, _ :: binary>>
        when code in @code_128_codes ->
        :code_128

      _ ->
        :string
    end
  end
end
