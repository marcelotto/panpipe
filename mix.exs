defmodule Panpipe.MixProject do
  use Mix.Project

  @repo_url "https://github.com/marcelotto/panpipe"

  @version File.read!("VERSION") |> String.trim()

  def project do
    [
      app: :panpipe,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      compilers: Mix.compilers ++ [:protocol_ex],
      deps: deps(),

      # Hex
      package: package(),
      description: description(),

      # Docs
      name: "Panpipe",
      docs: [
        source_url: @repo_url,
        source_ref: "v#{@version}",
        extras: ["CHANGELOG.md"]
      ]
    ]
  end

  defp description do
    """
    An Elixir wrapper around Pandoc.
    """
  end

  defp package do
    [
      maintainers: ["Marcel Otto"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @repo_url,
        "Changelog" => @repo_url <> "/blob/master/CHANGELOG.md"
      },
      files: ~w[lib priv mix.exs VERSION *.md]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:protocol_ex, "~> 0.4"},
      {:rambo, "~> 0.2"},

      # Development
      {:stream_data, "~> 0.5", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end
end
