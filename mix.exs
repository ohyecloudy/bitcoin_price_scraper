defmodule BitcoinPriceScraper.MixProject do
  use Mix.Project

  def project do
    [
      app: :bitcoin_price_scraper,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      config_path: "config/config.exs",
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 1.0"},
      {:tesla, "~> 1.4"},
      {:joken, "~> 2.3"},
      {:jason, "~> 1.1"},
      {:uuid, "~> 1.1"},
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_httpd, "~> 2.1"},
      {:telemetry, "~> 0.4.2"}
    ]
  end
end
