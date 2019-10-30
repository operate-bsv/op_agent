defmodule Operate.MixProject do
  use Mix.Project

  def project do
    [
      app: :operate,
      version: "0.1.0-beta.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Operate",
      description: "Agent for loading and running Functional Bitcoin programs.",
      source_url: "https://github.com/functional-bitcoin/agent",
      docs: [
        groups_for_modules: [
          "Extensions": [
            Operate.VM.Extension,
            Operate.VM.Extension.Agent,
            Operate.VM.Extension.Context,
            Operate.VM.Extension.Crypto,
            Operate.VM.Extension.JSON,
            Operate.VM.Extension.String
          ],
          "Adapters": [
            Operate.Adapter,
            Operate.Adapter.Bob,
            Operate.Adapter.FBHub
          ],
          "Caches": [
            Operate.Cache,
            Operate.Cache.ConCache,
            Operate.Cache.NoCache
          ],
        ]
      ],
      package: [
        name: "bsv",
        files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md),
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/functional-bitcoin/agent",
          "Website" => "https://www.operatebsv.org"
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
      {:tesla, "~> 1.2"}
    ]
  end
end
