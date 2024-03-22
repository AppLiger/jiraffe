defmodule Jiraffe.Support.TestHelpers do
  @moduledoc """
  Helpers for defining test cases.
  """

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
end
