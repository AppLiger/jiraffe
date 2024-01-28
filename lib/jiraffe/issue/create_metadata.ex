defmodule Jiraffe.Issue.CreateMetadata do
  @moduledoc """
  This resource returns the metadata required to create an issue. The fields
  returned depend on whether the user has permission to edit the issue and on
  whether the `update` parameter is set to `true` in the query string.

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issue-metadata/#api-rest-api-2-issue-createmeta-get)
  """

  alias __MODULE__
  alias Jiraffe.{Client, Error}

  defstruct expand: nil,
            projects: []

  @type t() :: %__MODULE__{}

  @doc """
  Converts a map (received from Jira API) to `Jira.Issue.CreateMetadata` struct.
  """
  def new(body) do
    %__MODULE__{
      expand: body["expand"],
      projects: Map.get(body, "projects", []) |> Enum.map(&CreateMetadata.Project.new/1)
    }
  end

  @doc """
  (**DEPRECATED**) Returns details of projects, issue types within projects,
  and, when requested, the create screen fields for each issue type for the user.

  ## Examples

      iex> Jiraffe.Issue.CreateMetadata.get()
      {:ok,
       %Jiraffe.Issue.CreateMetadata{
         expand: "projects.issuetypes.fields",
         fields: %{}
        }
      }
  """
  @spec get(client :: Client.t(), params :: Keyword.t()) ::
          {:ok, t()} | {:error, Error.t()}
  def get(client, params) do
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
