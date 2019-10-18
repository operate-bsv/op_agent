defmodule FBAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :fb_agent,
      version: "0.1.0-dev.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        groups_for_modules: [
          "Adapters": [
            FBAgent.Adapter,
            FBAgent.Adapter.Bob,
            FBAgent.Adapter.FBHub
          ],
          "Caches": [
            FBAgent.Cache,
            FBAgent.Cache.ConCache,
            FBAgent.Cache.NoCache
          ],
        ]
      ]
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
      {:bsv, "~> 0.2"},
      {:con_cache, "~> 0.14"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:jason, "~> 1.1"},
      {:luerl, git: "https://github.com/libitx/luerl.git", branch: "develop"},
      {:tesla, "~> 1.2.1"}
    ]
  end
end
