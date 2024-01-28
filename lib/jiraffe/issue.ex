defmodule Jiraffe.Issue do
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

  defstruct expand: nil,
            id: nil,
            self: nil,
            key: nil,
            rendered_fields: %{},
            properties: %{},
            names: %{},
            schema: %{},
            transitions: [],
            operations: [],
            editmeta: %{},
            changelog: nil,
            versioned_representations: nil,
            fields_to_include: nil,
            fields: %{}

  @type t() :: %__MODULE__{}
  @type error() :: {:error, Error.t()}

  @doc """
  Converts a map (received from Jira API) to `Jira.Issue` struct.
  """
  def new(body) do
    %__MODULE__{
      expand: body["expand"],
      id: body["id"],
      self: body["self"],
      key: body["key"],
      rendered_fields: Map.get(body, "renderedFields", %{}),
      properties: Map.get(body, "properties", %{}),
      names: Map.get(body, "names", %{}),
      schema: Map.get(body, "schema", %{}),
      transitions: Map.get(body, "transitions", []),
      operations: Map.get(body, "operations", []),
      editmeta: Map.get(body, "editmeta", %{}),
      changelog: body["changelog"],
      versioned_representations: body["versionedRepresentations"],
      fields_to_include: body["fieldsToInclude"],
      fields: Map.get(body, "fields", %{})
    }
  end

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
        {:ok, new(body)}

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
      {:ok, %{body: _body, status: 204}} ->
        {:ok, %{id: id}}

      {:ok, response} ->
        {:error, Error.new(:cannot_update_issue, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end

  @doc """
  Returns the edit screen fields for an issue that are visible to and editable by the user.
  """
  def get_edit_issue_metadata(client, issue_id_or_key, params \\ []) do
    case Jiraffe.get(
           client,
           "/rest/api/2/issue/#{issue_id_or_key}/editmeta",
           query: params
         ) do
      {:ok, %{status: 200, body: editmeta}} ->
        {:ok, editmeta}

      {:ok, response} ->
        {:error, Error.new(:cannot_get_edit_issue_metadata, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end

  @doc """
  (**DEPRECATED**) Returns details of projects, issue types within projects,
  and, when requested, the create screen fields for each issue type for the user.
  """
  def get_create_issue_metadata(client, params) do
    case Jiraffe.get(
           client,
           "/rest/api/2/issue/createmeta",
           query: params
         ) do
      {:ok, %{body: body, status: 200}} ->
        {:ok, body}

      {:ok, %{body: body}} ->
        {:error, Error.new(:cannot_get_crete_meta, body)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
