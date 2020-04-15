defmodule Rubicon.TestServer do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def barcode_scanned(barcode) do
    GenServer.call(__MODULE__, {:barcode, barcode})
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_call({:barcode, barcode}, _from, s) do
    Logger.debug "Begin Test: #{barcode}"
    {:reply, :ok, s}
  end
end
