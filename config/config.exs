# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :rubicon, target: Mix.target()

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1584672570"

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :rubicon, :viewport, %{
  name: :main_viewport,
  size: {800, 480},
  default_scene: {Rubicon.UI, nil},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "rubicon"]
    }
  ]
}

config :rubicon, :barcode, %{
  devices: [
    %{
      module: Rubicon.Barcode.HIDRawDevice,
      framing: Rubicon.Barcode.Framing.SymbolFraming,
      filters: [
        %{name: "ﾩSymbol Technologies, Inc, 2002 Symbol Bar Code Scanner"},
        %{name: "Symbol Technologies, Inc, 2008 Symbol Bar Code Scanner"}
      ]
    },
    %{
      module: Rubicon.Barcode.HIDRawDevice,
      framing: Rubicon.Barcode.Framing.HIDKeyboardNewLineFraming,
      filters: [
        %{name: "BarCode WPM USB"}
      ]
    }
  ]
}

config :logger, backends: [RingLogger]

if Mix.target() != :host do
  import_config "target.exs"
end
