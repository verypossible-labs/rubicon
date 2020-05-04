defmodule Rubicon.MixProject do
  use Mix.Project

  @app :rubicon
  @version "0.1.0"
  @all_targets [:rpi3, :rpi4]

  def project do
    [
      aliases: [loadconfig: [&bootstrap/1]],
      app: @app,
      archives: [nerves_bootstrap: "~> 1.7"],
      build_embedded: true,
      deps: deps(),
      docs: [main: "Rubicon", extras: ["docs/local-development.md"]],
      elixir: "~> 1.9",
      preferred_cli_target: [run: :host, test: :host],
      releases: [{@app, release()}],
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Rubicon.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.6.0", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"},
      {:scenic, "~> 0.10"},
      {:nerves_hub_cli, "~> 0.1"},
      {:nerves_hal, "~> 0.1"},
      {:jason, "~> 1.0"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      {:nerves_pack, "~> 0.2", targets: @all_targets},
      {:scenic_driver_nerves_rpi, "~> 0.10", targets: @all_targets},
      {:scenic_driver_nerves_touch, "~> 0.9", targets: @all_targets},
      {:hidraw, "~> 0.1", targets: @all_targets},

      # Dependencies for specific targets
      {:nerves_system_rpi3, "== 1.11.0", runtime: false, targets: :rpi3},
      {:scenic_driver_glfw, "~> 0.10", targets: :host}
    ] ++ nerves_hub(System.get_env("NERVES_HUB_ENABLE"))
  end

  def nerves_hub(nil), do: []
  def nerves_hub(_) do
    [
      {:nerves_hub_link, "~> 0.1", targets: @all_targets},
      {:nerves_key, "~> 0.1", targets: @all_targets}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "rubicon",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
