defmodule Exjpet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exjpet,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(Mix.env)
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps(:test) do
    mandatory_deps() ++
    [
      {:httpoison, "~> 0.13.0"},
    ]
  end

  defp deps(_) do
    mandatory_deps()
  end

  defp mandatory_deps do
    [
      {:poison, "~> 3.1"},
      {:ejpet, "~> 0.7.0"}
    ]
  end
end
