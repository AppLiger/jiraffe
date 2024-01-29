defmodule Jiraffe.Issue do
  @moduledoc """
  Jira issue CRUD operations and struct.

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
            edit_meta: Jiraffe.Issue.EditMetadata.new(%{}),
            changelog: nil,
            versioned_representations: nil,
            fields_to_include: nil,
            fields: %{}

  @type t() :: %__MODULE__{}
  @type error() :: {:error, Error.t()}

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.Issue` struct.
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
      edit_meta: Map.get(body, "editmeta", %{}) |> Jiraffe.Issue.EditMetadata.new(),
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
end
