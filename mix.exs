defmodule Panpipe.MixProject do
  use Mix.Project

  def project do
    [
      app: :panpipe,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      compilers: Mix.compilers ++ [:protocol_ex],
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
      {:porcelain, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:protocol_ex, "~> 0.4"},
      {:stream_data, "~> 0.4", only: :test},

      # Development
      {:credo, "~> 1.1",   only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end
end
