defmodule Rubicon.USBDisk do
  use Nerves.HAL.Device.Spec,
    adapter: Rubicon.SCSIDeviceAdapter

  require Logger

  @mount "/root/rubicon_data"

  def start_link(_) do
    Nerves.HAL.Device.Spec.start_link(__MODULE__, %{mounted?: false}, name: __MODULE__)
  end

  def mounted?() do
    Nerves.HAL.Device.Spec.call(__MODULE__, :mounted?)
  end

  def read(file) do
    if mounted?() do
      File.read("#{@mount}/#{file}")
    else
      {:error, :no_disk}
    end
  end

  def write(file, data) do
    Path.join(@mount, file)
    |> Path.dirname()
    |> File.mkdir_p()

    if mounted?() do
      File.write("#{@mount}/#{file}", data, [:write, :sync])
    else
      {:error, :no_disk}
    end
  end

  def handle_discover(device, s) do
    Logger.debug("[SCSI Device] Discovered: #{inspect(device)}")
    {:connect, device, s}
  end

  def handle_connect(device, s) do
    Logger.debug("[SCSI Device] Connected: #{inspect(device)}")
    block_device_path = Path.join([device.devpath, "device", "block"])
    File.mkdir_p!(@mount)

    with {:ok, [block_device]} <- File.ls(block_device_path),
         {_, 0} <- System.cmd("mount", ["/dev/#{block_device}1", @mount]) do
      Logger.debug("[SCSI Device] mounted")
      {:noreply, %{s | mounted?: true}}
    else
      _e ->
        {:noreply, s}
    end
  end

  def handle_call(:mounted?, _from, %{mounted?: mounted?} = s) do
    {:reply, mounted?, s}
  end

  def handle_disconnect(device, s) do
    Logger.debug("[SCSI Device] Connected: #{inspect(device)}")
    {:noreply, s}
  end

  def handle_data_in(_device, _data, s) do
    {:noreply, s}
  end
end
