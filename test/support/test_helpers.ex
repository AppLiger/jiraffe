defmodule Jiraffe.Support.TestHelpers do
  @moduledoc """
  Helpers for defining test cases.
  """

  @doc """
  Setup mocks for current test.

  As opposed to `Tesla.Mock.mock/1`, if the request body contains JSON
  the function `fun` gets `env.body` parsed to a map to ease the request matching.
  """
  @spec mock((Tesla.Env.t() -> Tesla.Env.t() | {integer(), map(), any()})) :: :ok
  def mock(fun) when is_function(fun) do
    Tesla.Mock.mock(fn env ->
      env = decode(env)
      fun.(env)
    end)
  end

  defdelegate mock(fun), to: Tesla.Mock

  def jira_response_body(file) do
    path = file_path(file)

    case File.read(path) do
      {:ok, body} ->
        Jason.decode!(body)

      {:error, reason} ->
        raise "Cannot read file: #{path} (#{reason})"
    end
  end

  defp file_path(file) do
    Path.join(["test/support/responses", file <> ".json"])
  end

  defp decode(env) do
    if decodable?(env) do
      %{env | body: Jason.decode!(env.body, keys: :atoms)}
    else
      env
    end
  end

  defp decodable?(env), do: decodable_body?(env) && decodable_content_type?(env)

  defp decodable_body?(env) do
    (is_binary(env.body) && env.body != "") || (is_list(env.body) && env.body != [])
  end

  defp decodable_content_type?(env) do
    case Tesla.get_header(env, "content-type") do
      nil -> false
      content_type -> String.starts_with?(content_type, "application/json")
    end
  end
end
