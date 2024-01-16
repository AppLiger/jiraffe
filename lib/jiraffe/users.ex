defmodule Jiraffe.Users do
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

  @doc """
  **EXPERIMENTAL**
  Return a page of users matching the provided criteria.
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
      {:ok, %{body: result, status: 200}} ->
        {:ok, result}

      {:ok, %{body: result}} ->
        {:error, %Error{reason: :cannot_get_users_list, details: result}}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end

  @doc """
  Returns a stream of pages (see Jiraffe.Users.get_bulk/2 for more info).
  """
  def get_bulk_stream(client, params) do
    per_page = Keyword.get(params, :maxResults, 50)

    Jiraffe.stream_pages(
      fn pagination_params ->
        params = Keyword.merge(params, pagination_params, fn _key, _v1, v2 -> v2 end)

        get_bulk(client, params)
      end,
      per_page
    )
  end

  @doc """
  Returns a paginated list of the users specified by one or more account IDs.
  """
  def get_bulk_all(client, params) do
    users =
      get_bulk_stream(client, params)
      |> Stream.flat_map(fn
        %{"values" => values} -> values
        _ -> []
      end)
      |> Enum.to_list()

    {:ok, users}
  rescue
    error ->
      {:error, Error.new(:cannot_get_users_list, error)}
  end
end
