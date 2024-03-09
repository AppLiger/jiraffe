defmodule Jiraffe.User.BulkGet do
  @moduledoc false

  use Jiraffe.Pagination

  alias Jiraffe.{Error, ResultsPage, User}

  @type account_id() :: String.t()

  @spec page(
          Jiraffe.Client.t(),
          params :: User.bulk_get_params()
        ) ::
          {:ok, ResultsPage.t()} | {:error, Error.t()}
  def page(client, params) do
    params =
      [
        accountId: Keyword.get(params, :account_ids),
        maxResults: Keyword.get(params, :max_results),
        startAt: Keyword.get(params, :start_at)
      ]
      |> Keyword.reject(fn {_, v} -> is_nil(v) end)

    case Jiraffe.get(
           client,
           "/rest/api/2/user/bulk",
           query: params
         ) do
      {:ok, %{body: body, status: 200}} ->
        users = Map.get(body, "values", []) |> Enum.map(&User.new/1)

        {:ok,
         %ResultsPage{
           start_at: Map.get(body, "startAt", 0),
           max_results: Map.get(body, "maxResults", Enum.count(users)),
           is_last: Map.get(body, "isLast", Enum.empty?(users)),
           total: Map.get(body, "total", 0),
           values: users
         }}

      {:ok, %{body: body}} ->
        {:error, %Error{reason: :cannot_get_users_list, details: body}}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
