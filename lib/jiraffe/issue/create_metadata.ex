defmodule Jiraffe.Issue.CreateMetadata do
  @moduledoc """
  This struct represents the metadata required to create an issue. The fields
  returned depend on whether the user has permission to edit the issue and on
  whether the `update` parameter is set to `true` in the query string.

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issue-metadata/#api-rest-api-2-issue-createmeta-get)
  """

  alias __MODULE__
  alias Jiraffe.Error

  defstruct expand: nil,
            projects: []

  @type t() :: %__MODULE__{
          expand: String.t() | nil,
          projects: [CreateMetadata.Project.t()]
        }

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.Issue.CreateMetadata` struct.
  """
  @spec new(map()) :: t()
  def new(body) do
    %__MODULE__{
      expand: body["expand"],
      projects: Map.get(body, "projects", []) |> Enum.map(&CreateMetadata.Project.new/1)
    }
  end

  @doc false
  @spec get(client :: Jiraffe.client(), params :: Jiraffe.Issue.get_create_metadata_params()) ::
          {:ok, t()} | {:error, Error.t()}
  def get(client, params) do
    params =
      [
        projectIds: Keyword.get(params, :project_ids),
        projectKeys: Keyword.get(params, :project_keys),
        issuetypeIds: Keyword.get(params, :issue_type_ids),
        issuetypeNames: Keyword.get(params, :issue_type_names),
        expand: Keyword.get(params, :expand)
      ]
      |> Keyword.reject(fn {_, v} -> is_nil(v) end)

    case Jiraffe.get(
           client,
           "/rest/api/2/issue/createmeta",
           query: params
         ) do
      {:ok, %{body: body, status: 200}} ->
        {:ok, new(body)}

      {:ok, %{body: body}} ->
        {:error, Error.new(:cannot_get_crete_meta, body)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
