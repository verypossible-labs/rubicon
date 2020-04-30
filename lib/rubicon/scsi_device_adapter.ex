defmodule Rubicon.SCSIDeviceAdapter do
  alias Nerves.HAL.Device
  use Device.Adapter, subsystem: "scsi_device"

  def attributes(_device) do
    :ok
  end

  def handle_connect(_device, s) do
    {:ok, s}
  end
end
