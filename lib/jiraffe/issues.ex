defmodule Jiraffe.Issues do
  @moduledoc """
  This resource represents Jira issues. Use it to:

    - create or edit issues, individually or in bulk.
    - retrieve metadata about the options for creating or editing issues.
    - delete an issue.
    - assign a user to an issue.
    - get issue changelogs.
    - send notifications about an issue.
    - get details of the transitions available for an issue.
    - transition an issue.
    - Archive issues.
    - Unarchive issues.
    - Export archived issues.

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/)
  """
  alias Jiraffe.{Client, Error}

  @type t() :: map()
  @type error() :: {:error, Error.t()}

  @doc """
  Get an issue by ID or key

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get)
  """
  @spec get(
          client :: Client.t(),
          id_or_key :: binary(),
          params :: Keyword.t()
        ) :: {:ok, t()} | error()
  def get(client, id_or_key, params \\ []) do
    case Jiraffe.get(client, "/rest/api/2/issue/" <> id_or_key, query: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, result} ->
        {:error, Error.new(:unexpected_status, result)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
