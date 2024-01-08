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

  @doc """
  Creates upto 50 issues and, where the option to create subtasks is enabled in Jira, subtasks.

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-bulk-post)
  """
  @spec bulk_create(
          client :: Client.t(),
          body :: map()
        ) :: {:ok, map()} | error()
  def bulk_create(client, body) do
    case Jiraffe.post(
           client,
           "/rest/api/2/issue/bulk",
           body
         ) do
      {:ok, %{status: 201, body: result}} ->
        {:ok, result}

      {:ok, response} ->
        {:error, Error.new(:cannot_create_issues, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end

  @doc """
  Edits an issue. A transition may be applied and issue properties updated as part of the edit.
  """
  @spec update(
          client :: Client.t(),
          id :: String.t(),
          body :: map()
        ) :: {:ok, %{id: String.t()}} | error()
  def update(client, id, body) do
    case Jiraffe.put(
           client,
           "/rest/api/2/issue/#{id}",
           body
         ) do
      {:ok, %{body: body, status: 204}} ->
        {:ok, body}

      {:ok, response} ->
        {:error, Error.new(:cannot_update_issue, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
