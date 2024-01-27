defmodule Jiraffe.Permission do
  @moduledoc """
  This resource represents permissions.
  Use it to obtain details of all permissions and determine whether the user has certain permissions.
  """

  alias Jiraffe.{Client, Error}

  @doc """
  Returns a list of permissions indicating which permissions the user has.
  Details of the user's permissions can be obtained in a global, project, issue or comment context.
  """

  @spec get_my_permissions(
          client :: Client.t(),
          params :: Keyword.t()
        ) :: {:ok, map()} | {:error, Error.t()}
  def get_my_permissions(client, params \\ []) do
    case Jiraffe.get(
           client,
           "/rest/api/2/mypermissions",
           query: params
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, response} ->
        {:error, Error.new(:cannot_get_my_permissions, response)}

      {:error, reason} ->
        {:error, Error.new(:cannot_get_my_permissions, reason)}
    end
  end
end
