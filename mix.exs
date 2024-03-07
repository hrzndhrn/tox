defmodule Tox.MixProject do
  use Mix.Project

  @source_url "https://github.com/hrzndhrn/tox"
  @version "0.2.4"

  def project do
    [
      app: :tox,
      version: @version,
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
      main: "readme",
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package do
    [
      maintainers: ["Marcus Kruse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp aliases do
    [
      carp: ["test --seed 0 --max-failures 1"]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test, runtime: false},
      {:recode, "~> 0.6", only: :dev},
      {:stream_data, "~> 0.5", only: [:dev, :test]},
      {:time_zone_info, "~> 0.5", only: [:test, :dev]}
    ]
  end
end
