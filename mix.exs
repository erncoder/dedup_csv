defmodule DedupCsv.MixProject do
  use Mix.Project

  def project do
    [
      app: :dedup_csv,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", [only: [:dev, :test], runtime: false]},
      {:csv, "~> 2.4.1"}
    ]
  end
end
