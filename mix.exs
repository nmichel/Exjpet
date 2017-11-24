defmodule Exjpet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exjpet,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
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
      {:poison, "~> 3.1"},
      {:jsx, "~> 2.8.0"},
      {:jsone, git: "https://github.com/sile/jsone.git", tag: "v0.3.3"},
      {:ejpet, "~> 0.7"}
    ]
  end
end
