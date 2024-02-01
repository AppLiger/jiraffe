defmodule Jiraffe.Issue do
  @moduledoc """
  Jira issue CRUD operations and struct.

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/)
  """

  alias __MODULE__
  alias Jiraffe.Error

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

  @type t() :: %__MODULE__{
          expand: String.t() | nil,
          id: String.t() | nil,
          self: String.t() | nil,
          key: String.t() | nil,
          rendered_fields: map(),
          properties: map(),
          names: map(),
          schema: map(),
          transitions: list(),
          operations: list(),
          edit_meta: Jiraffe.Issue.EditMetadata.t(),
          changelog: map() | nil,
          versioned_representations: map() | nil,
          fields_to_include: map() | nil,
          fields: map()
        }

  @type update_params() :: [
          notify_users: boolean(),
          override_screen_security: boolean(),
          override_editable_flag: boolean(),
          return_issue: boolean(),
          expand: String.t()
        ]

  @type get_create_metadata_params() :: [
          project_ids: list(non_neg_integer()),
          project_keys: list(String.t()),
          issue_type_ids: list(non_neg_integer()),
          issue_type_names: list(String.t()),
          expand: String.t()
        ]

  @type get_edit_metadata_params() :: [
          override_screen_security: boolean(),
          override_editable_flag: boolean()
        ]

  @type link_params() :: [
          type_id: String.t(),
          inward_issue_id: String.t(),
          outward_issue_id: String.t(),
          comment: map()
        ]

  @type jql_search_params() :: [
          jql: String.t(),
          start_at: non_neg_integer(),
          max_results: non_neg_integer(),
          validate_query: String.t(),
          fields: list(String.t()),
          expand: String.t(),
          properties: list(String.t()),
          fields_by_keys: boolean()
        ]

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
          client :: Jiraffe.client(),
          id_or_key :: binary(),
          params :: Keyword.t()
        ) :: {:ok, t()} | {:error, Error.t()}
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
          client :: Jiraffe.client(),
          id :: String.t(),
          body :: Issue.UpdateDetails.t(),
          params :: update_params()
        ) :: {:ok, %{id: String.t()}} | {:error, Error.t()}
  defdelegate update(client, id, body, params \\ []), to: Issue.Update

  @doc """
  Creates up to 50 issues and, where the option to create subtasks is enabled in Jira, subtasks.

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-bulk-post)
  """
  @spec bulk_create(
          client :: Jiraffe.client(),
          updates :: [Jiraffe.Issue.UpdateDetails.t()]
        ) :: {:ok, Jiraffe.Issue.BulkCreateResult.t()} | {:error, Error.t()}
  defdelegate bulk_create(client, updates), to: Issue.BulkCreate, as: :create

  @doc """
  (**DEPRECATED**) Returns details of projects, issue types within projects,
  and, when requested, the create screen fields for each issue type for the user.

  ## Examples

      Jiraffe.Issue.get_create_metadata(
        client,
        expand: "projects.issuetypes.fields"
      )

      {:ok,
        %Jiraffe.Issue.CreateMetadata{
          expand: "projects.issuetypes.fields",
          projects: []
        }
      }
  """
  @spec get_create_metadata(client :: Jiraffe.client(), params :: get_create_metadata_params()) ::
          {:ok, t()} | {:error, Error.t()}
  defdelegate get_create_metadata(client, params), to: Issue.CreateMetadata, as: :get

  @doc """
  Returns the edit screen fields for an issue that are visible to and editable by the user.
  """
  @spec get_edit_metadata(client :: Jiraffe.client(), params :: get_edit_metadata_params()) ::
          {:ok, Jiraffe.Issue.EditMetadata.t()} | {:error, Error.t()}
  defdelegate get_edit_metadata(client, issue_id_or_key, params \\ []),
    to: Issue.EditMetadata,
    as: :get

  @doc """
  Searches for issues using JQL.
  Returns a page of issues found using the JQL query.

  ## Params

  - `jql` - The [JQL](https://confluence.atlassian.com/x/egORLQ) search query.
  - `start_at` - The index of the first item to return in a page of results (page offset).
  - `max_results` - The maximum number of issues to return per page (defaults to 50).
  - `validate_query` - Determines how to validate the JQL query and treat the validation results.
    - `strict`
    - `warn`
    - `none`
  - `fields` - A list of fields to return for each issue, use it to retrieve a subset of fields.
    - `["summary", "comment"]` - Returns only the summary and comments fields.
    - `["-description"] - Returns all navigable (default) fields except description.
    - `["*all", "-comment"] - Returns all fields except comments.
  - `expand` - Use [expand](https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/#expansion) to include additional information about issues in the response.
    - `renderedFields` - Returns field values rendered in HTML format.
    - `names` - Returns the display name of each field.
    - `schema` - Returns the schema describing a field type.
    - `transitions` - Returns all possible transitions for the issue.
    - `operations` - Returns all possible operations for the issue.
    - `editmeta`  - Returns information about how each field can be edited.
    - `changelog` - Returns a list of recent updates to an issue, sorted by date, starting from the most recent.
    - `versionedRepresentations` - Instead of fields, returns versionedRepresentations a JSON array containing each version of a field's value, with the highest numbered item representing the most recent version.
  - `properties` - A list of issue property keys for issue properties to include in the results.
  - `fields_by_keys` - Whether fields in `fields` are referenced by keys rather than IDs.

  ## Examples:
      Jiraffe.Issue.jql_search(
        client, jql: "project = EX",
        max_results: 2
        )

      {:ok, %{
        start_at: 0,
        max_results: 2,
        is_last: true,
        total: 2,
        values: [
          %Jiraffe.Issue{
            fields: %{"description" => "Bar", "summary" => "Foo"},
            id: "10002",
            key: "EX-1",
            self: "https://your-domain.atlassian.net/rest/api/2/issue/10002"
          },
          %Jiraffe.Issue{
            fields: %{"description" => "Qux", "summary" => "Baz"},
            id: "10003",
            key: "EX-2",
            self: "https://your-domain.atlassian.net/rest/api/2/issue/10003"
          }
      ]}}
  """
  @spec jql_search(
          Jiraffe.client(),
          params :: jql_search_params()
        ) :: {:ok, t()} | {:error, Error.t()}
  defdelegate jql_search(client, params), to: Issue.JqlSearch, as: :page

  @doc """
  Searches for issues using JQL.
  Returns the issues found using the JQL query.
  """
  @spec jql_search_all(
          Jiraffe.client(),
          params :: jql_search_params()
        ) :: Enum.t()
  defdelegate jql_search_stream(client, params), to: Issue.JqlSearch, as: :stream

  @doc """
  Searches for issues using JQL.
  Returns the issues found using the JQL query.
  """
  @spec jql_search_all(
          Jiraffe.client(),
          params :: jql_search_params()
        ) ::
          {:ok, [t()]} | {:error, Error.t()}
  defdelegate jql_search_all(client, params), to: Issue.JqlSearch, as: :all

  @doc """
  Creates a link between two issues.
  Use this operation to indicate a relationship between two issues
  and optionally add a comment to the from (outward) issue.
  """
  @spec link(
          client :: Jiraffe.client(),
          params :: link_params()
        ) :: {:ok, Issue.Link.t()} | {:error, Exception.t()}
  defdelegate link(client, params), to: Issue.Link, as: :create
end
