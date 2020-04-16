defmodule Rubicon.UI do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives

  @text_size 28
  @status_left "Scan a board to begin"
  @status_right ""

  def status_left(status) do
    GenServer.call(__MODULE__, {:set_status, :left, status})
  end

  def status_right(status) do
    GenServer.call(__MODULE__, {:set_status, :right, status})
  end

  def render_steps(steps) do
    GenServer.call(__MODULE__, {:render_steps, steps})
  end

  def render_step_result(step, result) do
    GenServer.call(__MODULE__, {:render_step_result, step, result})
  end

  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  def init(_, opts) do
    Process.register(self(), __MODULE__)

    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        rect_spec({width, height}, id: :color, fill: :black),
        text_spec(@status_left, id: :status_left, text_align: :left, translate: {10, 32}),
        text_spec(@status_right, id: :status_right, text_align: :right, translate: {width - 10, 32}),
        rect_spec({width, 2}, id: :color, fill: :white, translate: {0, 48}),
        group_spec([], id: :test_group)
      ])

    {:ok, %{
      steps: [],
      step_results: [],
      graph: graph},
    push: graph}
  end

  def handle_call({:set_status, :right, status}, _from, %{graph: graph} = s) do
    graph =
      graph
      |> Graph.modify(:status_right, &text(&1, status))

    {:reply, :ok, %{s | graph: graph}, push: graph}
  end

  def handle_call({:set_status, :left, status}, _from, %{graph: graph} = s) do
    graph =
      graph
      |> Graph.modify(:status_left, &text(&1, status))

    {:reply, :ok, %{s | graph: graph}, push: graph}
  end

  def handle_call(:reset, _from, %{graph: graph} = s) do
    graph =
      graph
      |> Graph.modify(:status_left, &text(&1, @status_left))
      |> Graph.modify(:status_right, &text(&1, @status_right))

    graph = Enum.reduce(s.steps, graph, &Graph.delete(&2, :"#{&1}"))

    {:reply, :ok, %{s | graph: graph, steps: [], step_results: []}, push: graph}
  end

  def handle_call({:render_steps, steps}, _from, %{graph: graph} = s) do
    {_, graph} =
      Enum.reduce(steps, {100, graph}, fn(title, {offset, graph}) ->
        offset = offset + 30
        color =
          case Enum.find(s.step_results, & elem(&1, 0) == title) do
            nil -> :white
            {_, :ok} -> :green
            _ -> :red
          end
        graph =
          Graph.add_to(graph, :test_group, &
            text(&1, "* " <> title, id: :"#{title}", text_align: :left, translate: {20, offset}, fill: color)
          )
        {offset, graph}
      end)
    {:reply, :ok, %{s | graph: graph, steps: steps}, push: graph}
  end

  def handle_call({:render_step_result, step, result}, _from, %{graph: graph} = s) do
    color =
      case result do
        :ok -> :green
        _ -> :red
      end
    Logger.debug "Render Step: #{inspect step} #{inspect color}"
    graph = Graph.modify(graph, :"#{step}", &update_opts(&1, fill: color))
    {:reply, :ok, %{s | graph: graph, step_results: [{step, result} | s.step_results]}, push: graph}
  end
end
