defmodule Rubicon.Barcode do
  @moduledoc """
  Supervise a set of barcode decoders
  """

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(%{devices: device_specs}) do
    children = Enum.with_index(device_specs) |> Enum.map(&device_to_child_spec/1)
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp device_to_child_spec({device_spec, id}) do
    module = Map.fetch!(device_spec, :module)
    args = Map.delete(device_spec, :module)

    %{
      id: id,
      start: {module, :start_link, [args]}
    }
  end
end
