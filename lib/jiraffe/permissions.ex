defmodule Jiraffe.Permissions do
  @moduledoc """
  This resource represents permissions.
  Use it to obtain details of all permissions and determine whether the user has certain permissions.
  """

  defmodule UserPermission do
    @moduledoc """
    This resource represents a user's permission.
    """

    defstruct id: nil,
              key: nil,
              name: nil,
              type: nil,
              description: nil,
              have_permission: false

    def new(attrs \\ %{}) do
      %__MODULE__{
        id: attrs["id"],
        key: attrs["key"],
        name: attrs["name"],
        type: attrs["type"],
        description: attrs["description"],
        have_permission: attrs["havePermission"]
      }
    end
  end

  alias Jiraffe.Permissions
  alias Jiraffe.{Error}

  @type my_permissions_params() :: [
          project_key: String.t(),
          project_id: String.t(),
          issue_key: String.t(),
          issue_id: String.t(),
          permissions: [String.t()],
          project_uuid: String.t(),
          project_configuration_uuid: String.t(),
          comment_id: String.t()
        ]

  @doc """
  Returns a list of permissions indicating which permissions the user has.
  Details of the user's permissions can be obtained in a global, project, issue or comment context.

  ## Params

  - `project_key` - The project key for the project.
  - `project_id` - The project id for the project.
  - `issue_key` - The issue key for the issue.
  - `issue_id` - The issue id for the issue.
  - `permissions` - (Required) A list of permission keys.
  - `project_uuid` - The UUID of the project.
  - `project_configuration_uuid` - The UUID of the project configuration.
  - `comment_id` - The ID of the comment.
  """

  @spec my_permissions(
          client :: Jiraffe.client(),
          params :: my_permissions_params()
        ) :: {:ok, map()} | {:error, Error.t()}
  def my_permissions(client, params) do
    params =
      [
        projectKey: Keyword.get(params, :project_key),
        projectId: Keyword.get(params, :project_id),
        issueKey: Keyword.get(params, :issue_key),
        issueId: Keyword.get(params, :issue_id),
        permissions: Keyword.get(params, :permissions),
        projectUuid: Keyword.get(params, :project_uuid),
        projectConfigurationUuid: Keyword.get(params, :project_configuration_uuid),
        commentId: Keyword.get(params, :comment_id)
      ]
      |> Keyword.reject(fn {_, value} -> is_nil(value) end)

    case Jiraffe.get(
           client,
           "/rest/api/2/mypermissions",
           query: params
         ) do
      {:ok, %{status: 200, body: body}} ->
        result =
          Map.new(
            body["permissions"],
            fn {permission, data} ->
              {permission, Permissions.UserPermission.new(data)}
            end
          )

        {:ok, result}

      {:ok, response} ->
        {:error, Error.new(:cannot_get_my_permissions, response)}

      {:error, reason} ->
        {:error, Error.new(:cannot_get_my_permissions, reason)}
    end
  end
end
