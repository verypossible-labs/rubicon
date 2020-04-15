defmodule Rubicon do
  use GenServer
  @behaviour RubiconAPI

  alias Rubicon.{UI, Target}

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handshake() do
    GenServer.call(__MODULE__, :handshake)
  end

  def exunit_results(results) do
    GenServer.call(__MODULE__, {:exunit_results, results})
  end

  def barcode_scanned(barcode) do
    GenServer.cast(__MODULE__, {:barcode, barcode})
  end

  def init(opts) do
    ifname = opts[:network_interface] || "eth0"
    VintageNet.subscribe(["interface", ifname])

    {:ok, %{
      ifname: ifname,
      target: nil
    }}
  end

  def handle_call(:handshake, _from, s) do
    UI.set_status("Board handshake")
    {:reply, :ok, s}
  end

  def handle_call({:exunit_results, _results}, _from, s) do

    {:reply, :ok, s}
  end

  def handle_cast({:barcode, sn}, %{target: %Target{board_serial: sn}} = s),
    do: {:noreply, s}
  def handle_cast({:barcode, sn}, %{target: %Target{board_serial: nil}} = s) do
    {:noreply, update_in(s, [:target, :board_serial], fn _ -> sn end)}
  end
  def handle_cast({:barcode, board_serial}, s) do
    UI.set_status("Unexpected barcode scan #{board_serial}")
    {:noreply, s}
  end

  # A board has connected
  def handle_info({VintageNet, ["interface", ifname, "lower_up"], false, true, _}, %{ifname: ifname} = s) do
    UI.set_status("Board connecting")
    {:noreply, s}
  end
  # A board has disconnected
  def handle_info({VintageNet, ["interface", ifname, "lower_up"], true, false, _}, %{ifname: ifname} = s) do
    UI.set_status("Board disconnected")
    {:noreply, s}
  end

  def handle_info(_message, s) do
    {:noreply, s}
  end
end
