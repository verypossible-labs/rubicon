defmodule Rubicon.Barcode.Framing do
  @callback init() :: any

  @callback decode(state :: any, frame :: binary) ::
              {:ok, barcode :: String.t(), state :: any}
              | {:none, state :: any}
              | {:error, reason :: term, state :: any}
end
