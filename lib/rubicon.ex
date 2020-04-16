defmodule Rubicon do
  use GenServer
  @handshake_timeout 20

  alias Rubicon.UI
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def handshake(handshake) do
    GenServer.call(__MODULE__, {:handshake, handshake})
  end

  def step_result(step, result) do
    GenServer.call(__MODULE__, {:step_result, step, result})
  end

  def ssl_signer() do
    GenServer.call(__MODULE__, :ssl_signer)
  end

  def barcode_scanned(barcode) do
    GenServer.cast(__MODULE__, {:barcode, barcode})
  end

  def init(opts) do
    System.cmd("epmd", ["-daemon"])
    ifname = opts[:network_interface] || "eth0"
    handshake_timeout = opts[:handshake_timeout] || @handshake_timeout
    VintageNet.subscribe(["interface", ifname])

    host_address =
      VintageNet.get(["interface", "eth0", "addresses"])
      |> hd()
      |> Map.get(:address)
      |> :inet.ntoa()
      |> List.to_string()

    Node.start(:"rubicon@#{host_address}")

    {:ok, %{
      ifname: ifname,
      status: :idle,
      target_id: nil,
      target_handshake: nil,
      handshake_timeout: handshake_timeout,
      handshake_time_remaining: handshake_timeout,
      handshake_timer: nil
    }}
  end

  def handle_call({:handshake, handshake}, _from, s) do
    {:reply, :ok, %{s | target_handshake: handshake}}
  end

  def handle_call({:step_result, step, result}, _from, s) do
    Logger.debug("Step: #{inspect step}\nResult: #{inspect result}")
    UI.render_step_result(step, result)
    {:reply, :ok, s}
  end

  def handle_call(:ssl_signer, _from, s) do
    {:reply, :ok, s}
  end

  def handle_cast({:barcode, id}, %{target_id: id} = s),
    do: {:noreply, s}
  def handle_cast({:barcode, id}, %{target_id: nil, target_handshake: nil} = s) do
    UI.status_left("Target: #{id}")
    show_time_remaining(s)
    {:ok, handshake_timer} = :timer.send_interval(1_000, :handshake_timer)
    {:noreply, %{s | target_id: id, handshake_timer: handshake_timer}}
  end
  def handle_cast({:barcode, id}, %{target_id: nil} = s) do
    UI.status_left("Target: #{id}")
    UI.status_right("testing")
    UI.render_steps(s.target_handshake)
    {:noreply, %{s | target_id: id}}
  end
  def handle_cast({:barcode, _board_serial}, s) do
    {:noreply, s}
  end

  # A board has connected
  def handle_info({VintageNet, ["interface", ifname, "lower_up"], false, true, _}, %{ifname: ifname} = s) do
    Logger.debug "Board connected"
    {:noreply, s}
  end
  # A board has disconnected
  def handle_info({VintageNet, ["interface", ifname, "lower_up"], true, false, _}, %{handshake_timer: nil, ifname: ifname} = s) do
    Logger.debug "Board disconnected"
    {:noreply, reset(s)}
  end

  def handle_info(:handshake_timer, %{target_handshake: nil, handshake_time_remaining: 0} = s) do
    {:noreply, reset(s)}
  end
  def handle_info(:handshake_timer, %{target_handshake: nil} = s) do
    handshake_time_remaining = s.handshake_time_remaining - 1
    show_time_remaining(s)
    {:noreply, %{s | handshake_time_remaining: handshake_time_remaining}}
  end

  def handle_info(:handshake_timer, s) do
    UI.status_right("testing")
    UI.render_steps(s.target_handshake)
    {:noreply, reset_handshake_timer(s)}
  end

  def handle_info(_message, s) do
    {:noreply, s}
  end

  defp reset(s) do
    UI.reset()
    s
    |> reset_handshake_timer()
    |> reset_target()
  end

  defp reset_handshake_timer(%{handshake_timer: nil} = s) do
    %{s | handshake_time_remaining: s.handshake_timeout}
  end
  defp reset_handshake_timer(%{handshake_timer: timer_ref} = s) do
    :timer.cancel(timer_ref)
    reset_handshake_timer(%{s | handshake_timer: nil})
  end

  defp reset_target(s) do
    %{s | target_id: nil, target_handshake: nil}
  end

  defp show_time_remaining(s) do
    UI.status_right("waiting: #{s.handshake_time_remaining}")
  end
end
