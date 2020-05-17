defmodule Rubicon.Barcode.HIDRawDevice do
  use Nerves.HAL.Device.Spec,
    adapter: Nerves.HAL.Device.Adapters.Hidraw

  require Logger

  def start_link(%{framing: framing} = args) do
    state = Map.put(args, :status, :disconnected)
    state = Map.put(state, :framing_state, framing.init())
    Nerves.HAL.Device.Spec.start_link(__MODULE__, state)
  end

  def handle_call(:status, _from, s) do
    {:reply, {:ok, s.status}, s}
  end

  defp is_match(_attributes, []) do
    false
  end

  defp is_match(attributes, [filter | filters]) do
    case attributes do
      ^filter ->
        true

      _ ->
        is_match(attributes, filters)
    end
  end

  def handle_discover(device, %{filters: filters} = s) do
    {adapter, _opts} = __adapter__()

    attributes = adapter.attributes(device)

    if is_match(attributes, filters) do
      Logger.debug("[Barcode] Discovered device #{inspect(attributes)}")
      {:connect, device, s}
    else
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

  def handle_data_in(
        _device,
        data,
        %{framing: framing, framing_state: original_framing_state} = s
      )
      when is_binary(data) do
    framing_state =
      case framing.decode(original_framing_state, data) do
        {:ok, barcode, state} ->
          Logger.debug("[Barcode] Decoded barcode: #{inspect(barcode)}")
          Rubicon.barcode_scanned(barcode)
          state

        {:none, state} ->
          state

        {:error, reason, state} ->
          Logger.warn("[Barcode] Framing error: #{inspect(reason)}")
          state
      end

    s = %{s | framing_state: framing_state}
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
