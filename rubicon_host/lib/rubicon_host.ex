defmodule RubiconHost do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  @note """
    Waiting for connection...
  """

  @text_size 32

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    Process.register(self(), __MODULE__)
    VintageNet.subscribe(["interface", "eth0"])

    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    x_center = (width / 2)
    y_center = (height / 2)

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        rect_spec({width, height}, id: :color, fill: :black),
        text_spec(@note, id: :title, text_align: :center, translate: {x_center, y_center}),
      ])

    host_address =
      VintageNet.get(["interface", "eth0", "addresses"])
      |> hd()
      |> Map.get(:address)
      |> :inet.ntoa()
      |> List.to_string()

    Node.start(:"rubicon-host@#{host_address}")

    {:ok, graph, push: graph}
  end

  def handle_info({VintageNet, ["interface", "eth0", "lower_up"], false, true, %{}}, graph) do
    graph =
      graph
      |> Graph.modify(:title, &text(&1, "Connecting to board..."))

    {:noreply, graph, push: graph}
  end

  def handle_info({VintageNet, ["interface", "eth0", "lower_up"], true, false, %{}}, graph) do
    graph =
      graph
      |> Graph.modify(:title, &text(&1, @note, fill: :white))
      |> Graph.modify(:color, &update_opts(&1, fill: :black))

    {:noreply, graph, push: graph}
  end

  def handle_info(message, s) do
    Logger.debug "Unhandled message: #{inspect message}"
    {:noreply, s}
  end

  def handle_call({:set_status, status}, _from, graph) do
    graph =
      graph
      |> Graph.modify(:title, &text(&1, status))

    {:reply, :ok, graph, push: graph}
  end

  def handle_call({:test_results, {_io_data, results}}, _from, graph) do
    passed? = Map.get(results, :failures, 0) == 0
    passed_result = if passed?, do: "Pass", else: "Fail"
    color = if passed?, do: :green, else: :red

    results = """
    #{passed_result}

    failures: #{results.failures}
    total:    #{results.total}
    """

    graph =
      graph
      |> Graph.modify(:title, &text(&1, results, fill: :black))
      |> Graph.modify(:color, &update_opts(&1, fill: color))

    {:reply, :ok, graph, push: graph}
  end
end
