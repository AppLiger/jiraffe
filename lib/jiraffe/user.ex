defmodule Jiraffe.User do
  @moduledoc """
  This resource represent users. Use it to:
    - get, get a list of, create, and delete users.
    - get, set, and reset a user's default issue table columns.
    - get a list of the groups the user belongs to.
    - get a list of user account IDs for a list of usernames or user keys.

  """

  alias Jiraffe.{Client, Error}

  @type account_id() :: String.t()

  @type t() :: map()

  use Jiraffe.Pagination,
    naming: [[page_fn: :get_bulk, stream: :get_bulk_stream, all: :get_bulk_all]]

  @doc """
  (**EXPERIMENTAL**) Returns a page of users matching the provided criteria.

  [Rerefence](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-users/#api-rest-api-2-user-bulk-get)
  """
  @spec get_bulk(
          Client.t(),
          params :: Keyword.t()
        ) ::
          {:ok, map()} | {:error, Error.t()}
  def get_bulk(client, params) do
    case Jiraffe.get(
           client,
           "/rest/api/2/user/bulk",
           query: params
         ) do
      {:ok, %{body: body, status: 200}} ->
        {:ok,
         %{
           start_at: Map.get(body, "startAt", 0),
           max_results: Map.get(body, "maxResults", 50),
           is_last: Map.get(body, "isLast", true),
           total: Map.get(body, "total", 0),
           values: Map.get(body, "values", [])
         }}

      {:ok, %{body: body}} ->
        {:error, %Error{reason: :cannot_get_users_list, details: body}}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
