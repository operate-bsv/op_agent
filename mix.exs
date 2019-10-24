defmodule FBAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :fb_agent,
      version: "0.1.0-beta.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "FBAgent",
      description: "Agent for loading and running Functional Bitcoin programs.",
      source_url: "https://github.com/functional-bitcoin/agent",
      docs: [
        groups_for_modules: [
          "Extensions": [
            FBAgent.VM.Extension,
            FBAgent.VM.Extension.Agent,
            FBAgent.VM.Extension.Context,
            FBAgent.VM.Extension.Crypto,
            FBAgent.VM.Extension.JSON,
            FBAgent.VM.Extension.String
          ],
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
      ],
      package: [
        name: "bsv",
        files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md),
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/functional-bitcoin/agent",
          "Website" => "https://functions.chronoslabs.net"
        }
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
