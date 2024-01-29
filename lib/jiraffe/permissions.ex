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
  alias Jiraffe.{Client, Error}

  @doc """
  Returns a list of permissions indicating which permissions the user has.
  Details of the user's permissions can be obtained in a global, project, issue or comment context.
  """

  @spec my_permissions(
          client :: Client.t(),
          params :: Keyword.t()
        ) :: {:ok, map()} | {:error, Error.t()}
  def my_permissions(client, params \\ []) do
    params =
      %{
        projectKey: Keyword.get(params, :project_key),
        projectId: Keyword.get(params, :project_id),
        issueKey: Keyword.get(params, :issue_key),
        issueId: Keyword.get(params, :issue_id),
        permissions: Keyword.get(params, :permissions),
        projectUuid: Keyword.get(params, :project_uuid),
        projectConfigurationUuid: Keyword.get(params, :project_configuration_uuid),
        commentId: Keyword.get(params, :comment_id)
      }
      |> Map.reject(fn {_, value} -> is_nil(value) end)

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
