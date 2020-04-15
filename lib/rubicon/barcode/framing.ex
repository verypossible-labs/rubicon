defmodule Rubicon.Barcode.Framing do
  @callback decode(frame :: binary) ::
              {:ok, barcode :: String.t()}
              | {:error, reason :: term}
end
