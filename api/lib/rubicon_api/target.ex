defmodule RubiconAPI.Target do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    System.cmd("epmd", ["-daemon"])
    ifname = opts[:network_interface]
    VintageNet.subscribe(["interface", ifname])

    {:ok, %{
      status: :disconnected,
      timer_ref: nil,
      host_address: nil,
      host_node: nil,
      ifname: ifname
    }}
  end

  def handle_info({VintageNet, ["interface", ifname, "lower_up"], false, true, %{}}, %{ifname: ifname} = s) do
    {:ok, timer_ref} = :timer.send_interval(1000, :connect)
    {:noreply, %{s | timer_ref: timer_ref}}
  end

  def handle_info({VintageNet, ["interface", ifname, "lower_up"], true, false, %{}}, %{ifname: ifname} = s) do
    {:noreply, disconnect(s)}
  end

  def handle_info(:connect, %{status: :disconnected, ifname: ifname} = s) do
    s =
      case VintageNet.get(["interface", ifname, "addresses"]) do
        nil ->
          s

        [%{address: my_address} | _] ->
          host_address = my_address |> subtract_one() |> ip_to_string()
          my_address = ip_to_string(my_address)
          my_node = :"rubicon-target@#{my_address}"
          host_node = :"rubicon@#{host_address}"
          {:ok, _pid} = Node.start(my_node)
          Logger.debug "Node started #{inspect my_node}"
          %{s | host_node: host_node, status: :connected}
      end
    {:noreply, s}
  end

  def handle_info(:connect, %{status: :connected, host_node: host_node} = s) do
    Logger.debug "Connecting to #{inspect host_node}"
    s =
      if Node.connect(host_node) do
          :timer.cancel(s.timer_ref)
          :timer.sleep(100)
          RubiconAPI.handshake(host_node)
          # run_tests(host_node)
          %{s | host_node: host_node}
      else
        s
      end
    {:noreply, s}
  end

  def handle_info(message, status) do
    Logger.debug "Unhandled message: #{inspect message}"
    {:noreply, status}
  end

  defp disconnect(%{timer_ref: nil} = s) do
    Node.stop()
    %{s | status: :disconnected, host_address: nil, host_node: nil}
  end

  defp disconnect(%{timer_ref: timer_ref} = s) do
    :timer.cancel(timer_ref)
    disconnect(%{s | timer_ref: nil})
  end

  defp run_tests(host_node) do
    {:ok, results} = ExUnitRelease.run()
    RubiconAPI.exunit_results(host_node, results)
  end

  defp ip_to_string(ip) do
    ip
    |> :inet.ntoa()
    |> List.to_string()
  end

  defp subtract_one({a, b, c, d}), do: {a, b, c, d - 1}
end
