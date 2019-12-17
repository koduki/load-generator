defmodule LoadGenerator.MixProject do
  use Mix.Project

  def project do
    [
      app: :loadgen,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  defp escript do
    [main_module: App.CLI]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
#      extra_applications: [:logger, :httpoison, :goth, :timex],
      extra_applications: [:logger, :httpoison, :timex],

applications: applications(Mix.env)
    ]
  end

  defp applications(:dev), do: applications(:all) ++ [:remix]
  defp applications(_all), do: [:logger]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:logger_file_backend, "~> 0.0.10"},
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.6"},
      {:poolboy, "~> 1.5.2"},
      {:google_api_pub_sub, "~> 0.16.0"},
      {:goth, "~> 1.1.0"},
      {:uuid, "~> 1.1" },
      {:timex, "~> 3.5"},
      {:mock, "~> 0.2.0", only: :test},
      {:remix, "~> 0.0.1", only: :dev}

      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
