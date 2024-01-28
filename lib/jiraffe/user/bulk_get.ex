defmodule Jiraffe.User.BulkGet do
  @moduledoc """
  Returns a paginated list of the users specified by one or more account IDs.
  """

  use Jiraffe.Pagination

  alias Jiraffe.{Client, Error}

  @type account_id() :: String.t()

  @doc """
  (**EXPERIMENTAL**) Returns a page of users matching the provided criteria.

  [Rerefence](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-users/#api-rest-api-2-user-bulk-get)
  """

  @spec page(
          Client.t(),
          params :: Keyword.t()
        ) ::
          {:ok, map()} | {:error, Error.t()}
  def page(client, params) do
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
           values: Map.get(body, "values", []) |> Enum.map(&Jiraffe.User.new/1)
         }}

      {:ok, %{body: body}} ->
        {:error, %Error{reason: :cannot_get_users_list, details: body}}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
