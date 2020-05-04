defmodule Rubicon do
  use GenServer
  @handshake_timeout 40

  alias Rubicon.{UI, USBDisk}
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__})
  end

  def handshake(handshake) do
    GenServer.call({:global, __MODULE__}, {:handshake, handshake}, :infinity)
  end

  def step_result(step, result) do
    GenServer.call({:global, __MODULE__}, {:step_result, step, result})
  end

  def ssl_signer() do
    GenServer.call({:global, __MODULE__}, :ssl_signer)
  end

  def firmware() do
    GenServer.call({:global, __MODULE__}, :firmware)
  end

  def barcode_scanned(barcode) do
    GenServer.cast({:global, __MODULE__}, {:barcode, barcode})
  end

  def init(opts) do
    System.cmd("epmd", ["-daemon"])
    ifname = opts[:network_interface] || "eth0"
    handshake_timeout = opts[:handshake_timeout] || @handshake_timeout
    VintageNet.subscribe(["interface", ifname])

    {:ok,
     %{
       ifname: ifname,
       status: :idle,
       target_id: nil,
       target_handshake: nil,
       handshake_timeout: handshake_timeout,
       handshake_time_remaining: handshake_timeout,
       handshake_timer: nil,
       handshake_from: nil,
       node: nil
     }, {:continue, VintageNet.get(["interface", ifname, "addresses"])}}
  end

  def handle_continue(nil, s), do: {:noreply, s}

  def handle_continue(addresses, s) do
    handle_addresses(addresses, s)
  end

  def handle_call({:handshake, handshake}, from, %{target_id: nil} = s) do
    Logger.debug("Handshake noreply")
    {:noreply, %{s | target_handshake: handshake, handshake_from: from}}
  end

  def handle_call({:handshake, handshake}, _from, s) do
    Logger.debug("Handshake reply call")
    {:reply, :ok, %{s | target_handshake: handshake}}
  end

  def handle_call(:firmware, _from, s) do
    {:reply, USBDisk.read("install.fw"), s}
  end

  def handle_call(:ssl_signer, _from, s) do
    reply =
      with {:ok, cert} <- USBDisk.read("signer-cert.pem"),
           {:ok, key} <- USBDisk.read("signer-key.pem") do
        {:ok, %{cert: cert, key: key}}
      end

    {:reply, reply, s}
  end

  def handle_call({:step_result, step, result}, _from, s) do
    Logger.debug("Step: #{inspect(step)}\nResult: #{inspect(result)}")
    UI.render_step_result(step, result)
    {:reply, :ok, s}
  end

  def handle_call({:finished, status, results}, _from, s) do
    Logger.debug("Tests finished: #{inspect(status)}")
    Logger.debug("Results: #{inspect(results)}")

    step_results = Enum.reduce(results, [], fn
      ({step, :ok}, acc) -> [%{step: step, status: :ok, output: ""} | acc]
      ({step, {status, output}}, acc) -> [%{step: step, status: status, output: output} | acc]
    end)
    data =
      %{
        status: status,
        target_id: s.target_id,
        step_results: step_results
      }
    data =
      case Jason.encode(data) do
        {:ok, data} -> data
        _ -> inspect(data)
      end

    USBDisk.write("target_output/#{s.target_id}.json", data)

    UI.render_result(status)
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
    {:noreply, reset_handshake_timer(%{s | target_id: id})}
  end

  def handle_cast({:barcode, _board_serial}, s) do
    {:noreply, s}
  end

  def handle_info(
        {VintageNet, ["interface", ifname, "addresses"], _, addresses, _},
        %{ifname: ifname, node: nil} = s
      ) do
    handle_addresses(addresses, s)
  end

  # A board has connected
  def handle_info(
        {VintageNet, ["interface", ifname, "lower_up"], false, true, _},
        %{ifname: ifname} = s
      ) do
    Logger.debug("Board connected")
    {:noreply, s}
  end

  # A board has disconnected
  def handle_info(
        {VintageNet, ["interface", ifname, "lower_up"], true, false, _},
        %{handshake_timer: nil, ifname: ifname} = s
      ) do
    Logger.debug("Board disconnected")
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

  def terminate(_reason, s) do
    Node.stop()
    {:stop, s}
  end

  defp handle_addresses(addresses, s) do
    case Enum.find(addresses, &(&1.family == :inet)) do
      %{address: address} ->
        address =
          address
          |> :inet.ntoa()
          |> List.to_string()

        {:noreply, start_node(address, s)}

      nil ->
        {:noreply, s}
    end
  end

  defp reset(s) do
    UI.reset()

    s
    |> reset_handshake_timer()
    |> reset_target()
  end

  defp reset_handshake_timer(%{handshake_timer: nil} = s) do
    if from = s.handshake_from do
      Logger.debug("Handshake reply")
      GenServer.reply(from, :ok)
    end

    %{s | handshake_from: nil, handshake_time_remaining: s.handshake_timeout}
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

  defp start_node(address, s) do
    {:ok, pid} = Node.start(:"rubicon@#{address}")
    %{s | node: pid}
  end

  defimpl Jason.Encoder, for: [MapSet, Range, Stream] do
    def encode(struct, opts) do
      Jason.Encode.list(Enum.to_list(struct), opts)
    end
  end

  defimpl Jason.Encoder, for: [Tuple] do
    def encode(tuple, opts) do
      Jason.Encode.list(Tuple.to_list(tuple), opts)
    end
  end
end
