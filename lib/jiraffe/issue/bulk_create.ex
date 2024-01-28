defmodule Jiraffe.Issue.BulkCreate do
  @moduledoc """
  Bulk create Jira issues.
  """

  @doc """
  Creates upto 50 issues and, where the option to create subtasks is enabled in Jira, subtasks.

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-bulk-post)
  """

  alias Jiraffe.{Client, Error}

  defstruct errors: [], issues: %{}

  @doc """
  Converts a map (received from Jira API) to `Jira.Issue.BulkCreate` struct.
  """
  @spec new(map()) :: %__MODULE__{}
  def new(body) do
    %__MODULE__{
      errors: Map.get(body, "errors", []) |> Enum.map(&Jiraffe.BulkOperationErrorResult.new/1),
      issues: Map.get(body, "issues", []) |> Enum.map(&Jiraffe.Issue.Created.new/1)
    }
  end

  @spec create(
          client :: Client.t(),
          body :: map()
        ) :: {:ok, map()} | {:error, Error.t()}
  def create(client, body) do
    case Jiraffe.post(
           client,
           "/rest/api/2/issue/bulk",
           body
         ) do
      {:ok, %{status: 201, body: body}} ->
        {:ok, new(body)}

      {:ok, response} ->
        {:error, Error.new(:cannot_create_issues, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
