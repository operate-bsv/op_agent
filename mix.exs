defmodule FB.MixProject do
  use Mix.Project

  def project do
    [
      app: :fb,
      version: "0.1.0-dev.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
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
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:jason, "~> 1.1"},
      {:tesla, "~> 1.2.1"},
      {:sandbox, "~> 0.3.0"}
    ]
  end
end
