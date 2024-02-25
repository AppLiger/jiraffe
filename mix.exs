defmodule Jiraffe.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :jiraffe,
      deps: deps(),
      description: description(),
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: "https://github.com/AppLiger/jiraffe",
      name: "Jiraffe",
      package: package(),
      source_url: "https://github.com/AppLiger/jiraffe",
      start_permanent: Mix.env() == :prod,
      test_coverage: [ignore_modules: [JiraffeTest.Support]],
      version: "0.1.1"
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
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      # optional, but recommended adapter
      {:hackney, "~> 1.17"},
      # required by JSON middleware
      {:jason, ">= 1.0.0"},
      {:tesla, "~> 1.4"}
    ]
  end

  defp description do
    "Jiraffe is an Elixir client library for interacting with Atlassian's Jira REST API."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/AppLiger/jiraffe"},
      name: "jiraffe"
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
