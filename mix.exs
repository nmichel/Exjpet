defmodule Exjpet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exjpet,
      version: "0.1.0",
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
      {:poison, "~> 3.1"},
      {:ejpet, "~> 0.7.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:httpoison, "~> 0.13.0", only: :test, runtime: false}
    ]
  end
end
