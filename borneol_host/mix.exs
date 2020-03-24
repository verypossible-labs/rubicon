defmodule BorneolHost.MixProject do
  use Mix.Project

  @app :borneol_host
  @version "0.1.0"
  @all_targets [:rpi3, :rpi4]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.7"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
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
      mod: {BorneolHost.Application, []},
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
      {:borneol_api, path: "../borneol_api"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      {:nerves_pack, "~> 0.2", targets: @all_targets},
      {:scenic_driver_nerves_rpi, "~> 0.10", targets: @all_targets},
      {:scenic_driver_nerves_touch, "~> 0.9", targets: @all_targets},

      # Dependencies for specific targets
      {:nerves_system_rpi3, "~> 1.11", runtime: false, targets: :rpi3},
      {:nerves_system_rpi4, "~> 1.11", runtime: false, targets: :rpi4},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "borneol",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
