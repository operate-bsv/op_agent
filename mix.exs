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
      description: "Operate | Agent is an Elixir agent used to load and run Bitcoin programs.",
      source_url: "https://github.com/operate-bsv/op_agent",
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
        name: "operate",
        files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md),
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/operate-bsv/op_agent",
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
      {:tesla, "~> 1.2"},
      luerl_dep(Mix.env)
    ]
  end

  defp luerl_dep(:publish), do: {:luerl, "~> 0.4"}
  defp luerl_dep(_),
    do: {:luerl, github: "rvirding/luerl", branch: "develop"}

end
