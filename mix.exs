defmodule Jiraffe.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :jiraffe,
      version: "0.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Jiraffe",
      description: description(),
      package: package()
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
      name: "jiraffe",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/AppLiger/jiraffe"}
    ]
  end
end
