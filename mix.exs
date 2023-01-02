defmodule RouleAvecSpot.MixProject do
  use Mix.Project

  def project do
    [
      app: :roule_avec_spot,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OAuth.Cache.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4.0"},
      {:jason, ">= 1.0.0"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
