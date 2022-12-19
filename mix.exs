defmodule Tox.MixProject do
  use Mix.Project

  def project do
    [
      app: :tox,
      version: "0.2.3",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      aliases: aliases(),
      description: description(),
      docs: docs(),
      package: package()
    ]
  end

  def description do
    "Some structs and functions to work with dates, times, durations, periods, and intervals."
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      main: "readme"
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/hrzndhrn/tox"},
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*",
        "CHANGELOG*"
      ]
    ]
  end

  defp dialyzer do
    [
      ignore_warnings: ".dialyzer_ignore.exs",
      plt_file: {:no_warn, "test/support/plts/dialyzer.plt"},
      flags: [:unmatched_returns]
    ]
  end

  defp preferred_cli_env do
    [
      carp: :test,
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.travis": :test,
      "coveralls.github": :test
    ]
  end

  defp elixirc_paths(env) do
    case env do
      :test -> ["lib", "test/support"]
      _else -> ["lib"]
    end
  end

  defp aliases do
    [
      carp: ["test --seed 0 --max-failures 1"]
    ]
  end

  defp deps do
    [
      {:cldr_calendars_coptic, "~> 1.0.0-rc.0", only: [:dev, :test]},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:earmark, "1.4.15", only: [:dev, :test], override: true},
      {:excoveralls, "~> 0.13", only: :test, runtime: false},
      {:ex_cldr_calendars, "~> 1.17-rc", only: [:dev, :test], override: true},
      {:ex_cldr_calendars_ethiopic, "~> 0.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:stream_data, "~> 0.5", only: [:dev, :test]},
      {:time_zone_info, "~> 0.5", only: [:test, :dev]}
    ]
  end
end
