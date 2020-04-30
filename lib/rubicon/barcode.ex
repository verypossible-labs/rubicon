defmodule Rubicon.Barcode do
  use Nerves.HAL.Device.Spec,
    adapter: Nerves.HAL.Device.Adapters.Hidraw

  require Logger

  @framing Rubicon.Barcode.SymbolFraming
  @handheld %{name: "ﾩSymbol Technologies, Inc, 2002 Symbol Bar Code Scanner"}
  @stationary %{name: "Symbol Technologies, Inc, 2008 Symbol Bar Code Scanner"}

  def start_link(_) do
    Nerves.HAL.Device.Spec.start_link(__MODULE__, %{status: :disconnected}, name: __MODULE__)
  end

  def status() do
    Nerves.HAL.Device.Spec.call(__MODULE__, :status)
  end

  def handle_call(:status, _from, s) do
    {:reply, {:ok, s.status}, s}
  end

  def handle_discover(device, s) do
    {adapter, _opts} = __adapter__()

    case adapter.attributes(device) do
      @stationary ->
        Logger.debug("[Barcode] Discovered")
        {:connect, device, s}

      @handheld ->
        Logger.debug("[Barcode] Discovered")
        {:connect, device, s}

      _ ->
        {:noreply, s}
    end
  end

  def handle_connect(_device, s) do
    Logger.debug("[Barcode] Connected")
    {:noreply, %{s | status: :connected}}
  end

  def handle_disconnect(_device, s) do
    Logger.debug("[Barcode] Disconnected")
    {:noreply, %{s | status: :disconnected}}
  end

  def handle_data_in(_device, data, s) when is_binary(data) do
    case @framing.decode(data) do
      {:ok, barcode} ->
        Logger.debug("[Barcode] #{inspect(barcode)}")
        Rubicon.barcode_scanned(barcode)

      {:error, reason} ->
        Logger.warn("[Barcode] Framing error: #{inspect(reason)}")
    end

    {:noreply, s}
  end

  def handle_data_in(_device, {:report_descriptor, descriptor}, s) do
    {:noreply, Map.put(s, :report_desc, descriptor)}
  end

  def handle_data_in(_device, data, s) do
    Logger.debug("[Barcode] Handled invalid data in: #{inspect(data)}")
    {:noreply, s}
  end
end
