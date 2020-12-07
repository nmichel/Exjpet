defmodule Exjpet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exjpet,
      version: "0.3.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description() do
    "The easy way to ejpet for Elixir"
  end

  defp package() do
    [
      name: "exjpet",
      maintainers: ["Nicolas Michel"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nmichel/Exjpet"}
    ]
  end

  defp deps do
    [
      {:ejpet, "~> 0.8.0"},
      {:jsone, "~> 1.5"},
      {:jason, "~> 1.2"},
      {:poison, "~> 4.0"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: :dev, runtime: false},
      {:httpoison, "~> 1.7", only: :test, runtime: false}
    ]
  end
end
