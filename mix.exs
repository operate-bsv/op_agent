defmodule Operate.MixProject do
  use Mix.Project

  def project do
    [
      app: :operate,
      version: "0.1.0-beta.11",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Operate",
      description: "Operate | Agent is an Elixir agent used to load and run Bitcoin programs.",
      source_url: "https://github.com/operate-bsv/op_agent",
      docs: [
        main: "Operate",
        groups_for_modules: [
          "Extensions": [
            Operate.VM.Extension,
            Operate.VM.Extension.Agent,
            Operate.VM.Extension.Base,
            Operate.VM.Extension.Context,
            Operate.VM.Extension.Crypto,
            Operate.VM.Extension.JSON,
            Operate.VM.Extension.String
          ],
          "Adapters": [
            Operate.Adapter,
            Operate.Adapter.Bob,
            Operate.Adapter.OpApi
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
        files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
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
      {:ex_doc, "~> 0.22", only: [:dev, :publish], runtime: false},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.1", only: :test},
      {:terminus, "~> 0.1"},
      {:tesla, "~> 1.3"},
      luerl_dep(Mix.env)
    ]
  end

  defp luerl_dep(:publish), do: {:luerl, "~> 0.4"}
  defp luerl_dep(_),
    do: {:luerl, github: "rvirding/luerl", branch: "develop"}

  defp elixirc_paths(:test), do: elixirc_paths(:default) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]

end
