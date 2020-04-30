defmodule Rubicon.UI do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  import Scenic.Components

  @timeout :infinity
  @text_size 28
  @status_left "Scan a board to begin"
  @status_right ""
  @prompt ""

  def status_left(status) do
    GenServer.call({:global, __MODULE__}, {:set_status, :left, status})
  end

  def status_right(status) do
    GenServer.call({:global, __MODULE__}, {:set_status, :right, status})
  end

  def render_steps(steps) do
    GenServer.call({:global, __MODULE__}, {:render_steps, steps})
  end

  def render_step_result(step, result) do
    GenServer.call({:global, __MODULE__}, {:render_step_result, step, result})
  end

  def render_result(result) do
    GenServer.call({:global, __MODULE__}, {:render_result, result})
  end

  def prompt_yn?(message, timeout \\ @timeout) do
    GenServer.call({:global, __MODULE__}, {:prompt_yn?, message}, timeout)
  end

  def reset() do
    GenServer.call({:global, __MODULE__}, :reset)
  end

  def init(_, opts) do
    :global.register_name(__MODULE__, self())

    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        rect_spec({width, height}, id: :color, fill: :black),
        text_spec(@status_left, id: :status_left, text_align: :left, translate: {10, 32}),
        text_spec(@status_right,
          id: :status_right,
          text_align: :right,
          translate: {width - 10, 32}
        ),
        rect_spec({width, 2}, id: :color, fill: :white, translate: {0, 48}),
        rect_spec({2, height - 48}, id: :color, fill: :white, translate: {width / 2, 48}),
        group_spec([], id: :test_group),
        group_spec(
          [
            text_spec(@prompt,
              id: :prompt,
              text_align: :left,
              translate: {width / 2 + 10, 88},
              fill: :yellow
            )
          ],
          id: :prompt_group
        )
      ])

    {:ok,
     %{
       steps: [],
       step_results: [],
       graph: graph,
       viewport_size: {width, height},
       prompt: nil
     }, push: graph}
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
      |> Graph.delete(:test_group)
      |> Graph.delete(:prompt_group)
      |> add_specs_to_graph([
        prompt_group_spec(s),
        test_group_spec()
      ])

    graph = Enum.reduce(s.steps, graph, &Graph.delete(&2, :"#{&1}"))

    {:reply, :ok, %{s | graph: graph, steps: [], step_results: [], prompt: nil}, push: graph}
  end

  def handle_call({:render_steps, steps}, _from, %{graph: graph} = s) do
    {_, graph} =
      Enum.reduce(steps, {100, graph}, fn title, {offset, graph} ->
        offset = offset + 30

        color =
          case Enum.find(s.step_results, &(elem(&1, 0) == title)) do
            nil -> :white
            {_, :ok} -> :green
            _ -> :red
          end

        graph =
          Graph.add_to(
            graph,
            :test_group,
            &text(&1, "* " <> title,
              id: :"#{title}",
              text_align: :left,
              translate: {20, offset},
              fill: color
            )
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

    Logger.debug("Render Step: #{inspect(step)} #{inspect(color)}")
    graph = Graph.modify(graph, :"#{step}", &update_opts(&1, fill: color))

    {:reply, :ok, %{s | graph: graph, step_results: [{step, result} | s.step_results]},
     push: graph}
  end

  def handle_call(
        {:render_result, result},
        _from,
        %{graph: graph, viewport_size: {width, height}} = s
      ) do
    color =
      case result do
        :pass -> :green
        :fail -> :red
      end

    graph =
      graph
      |> Graph.modify(:status_right, &text(&1, "Finished"))
      |> Graph.add_to(
        :prompt_group,
        &rect(&1, {width / 2, height - 50},
          id: :result_color,
          fill: color,
          translate: {width / 2, 50}
        )
      )
      |> Graph.add_to(
        :prompt_group,
        &text(&1, to_string(result),
          id: :result,
          text_align: :center,
          font_size: 128,
          translate: {width * 0.75, height * 0.5 + 50},
          fill: :black
        )
      )

    {:reply, :ok, %{s | graph: graph}, push: graph}
  end

  def handle_call({:prompt_yn?, message}, from, %{graph: graph} = s) do
    Logger.debug("Prompt Called")
    {width, height} = s.viewport_size
    graph = Graph.modify(graph, :prompt, &text(&1, message))

    graph =
      Graph.add_to(
        graph,
        :prompt_group,
        &button(&1, "Yes",
          id: :yes,
          width: 150,
          height: 50,
          theme: :success,
          translate: {width - 175, height - 150}
        )
      )
      |> Graph.add_to(
        :prompt_group,
        &button(&1, "No",
          id: :no,
          width: 150,
          height: 50,
          theme: :danger,
          translate: {width - 375, height - 150}
        )
      )

    {:noreply, %{s | prompt: from, graph: graph}, push: graph}
  end

  def handle_input(input, _ctx, state) do
    Logger.debug("Input: #{inspect(input)}")
    {:noreply, state}
  end

  def filter_event({:click, _} = event, _from, %{prompt: nil} = s) do
    Logger.debug("Clicked screen")
    {:cont, event, s, push: s.graph}
  end

  def filter_event({:click, button} = event, _from, %{graph: graph, prompt: prompt} = s) do
    Logger.debug("Clicked #{inspect(button)}")
    GenServer.reply(prompt, button)

    graph =
      graph
      |> Graph.delete(:prompt_group)
      |> add_specs_to_graph([
        prompt_group_spec(s)
      ])

    {:cont, event, %{s | prompt: nil, graph: graph}, push: graph}
  end

  def filter_event(event, _from, %{prompt: nil} = s) do
    Logger.debug("Rando event")
    {:cont, event, s}
  end

  def test_group_spec() do
    group_spec([], id: :test_group)
  end

  def prompt_group_spec(%{viewport_size: {width, _height}}) do
    group_spec(
      [
        text_spec(@prompt,
          id: :prompt,
          text_align: :left,
          translate: {width / 2 + 10, 88},
          fill: :yellow
        )
      ],
      id: :prompt_group
    )
  end
end
