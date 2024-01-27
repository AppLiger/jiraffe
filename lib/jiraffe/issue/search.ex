defmodule Jiraffe.Issue.Search do
  @moduledoc """
  This resource represents various ways to search for issues.
  Use it to search for issues with a JQL query and find issues to populate an issue picker.
  """
  alias Jiraffe.{Client, Error}

  @type t() :: map()
  @type error() :: {:error, Error.t()}

  @doc """
  Searches for issues using JQL.
  If the JQL query expression is too large to be encoded as a query parameter,
  use the POST version of this resource.
  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issue-search/#api-rest-api-2-search-get)

  ## Examples:
      iex> Jiraffe.Issue.Search.search_jql(client, jql: "project = EX", maxResults: 1)
      {:ok, %{
        "startAt" => 0,
        "maxResults" => 1,
        "isLast" => false,
        "total" => 2,
        "issues" => [
          %{
            "id" => "10002",
            "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002",
            "key" => "EX-1",
            "fields" => %{
              "summary" => "Foo",
              "description" => "Bar"
            }
          }
        ]
      }}
  """
  @spec search_jql(
          client :: Client.t(),
          params :: Keyword.t()
        ) :: {:ok, Enum.t()} | error()
  def search_jql(client, params) do
    case Jiraffe.get(client, "/rest/api/2/search", query: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, result} ->
        {:error, Error.new(:unexpected_status, result)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end

  @doc """
  Searches for issues using JQL.
  Returns a stream of pages (see Jiraffe.search_jql/2 for more info).
  """
  def search_jql_stream(client, params) do
    per_page = Keyword.get(params, :maxResults, 50)

    Jiraffe.stream_pages(
      fn pagination_params ->
        search_jql(client, Keyword.merge(params, pagination_params, fn _key, _v1, v2 -> v2 end))
      end,
      per_page
    )
  end

  @doc """
  Searches for issues using JQL.
  Returns a list of all issues found using the JQL query.

  ## Examples:
      iex> Jiraffe.Issue.Search.search_jql_all(client, jql: "project = EX", maxResults: 1)
      {:ok, [
        %{
          "fields" => %{"description" => "Bar", "summary" => "Foo"},
          "id" => "10002",
          "key" => "EX-1",
          "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002"
        },
        %{
          "fields" => %{"description" => "Qux", "summary" => "Baz"},
          "id" => "10003",
          "key" => "EX-2",
          "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10003"
        }
      ]}
  """
  @spec search_jql_all(
          client :: Client.t(),
          params :: Keyword.t()
        ) :: {:ok, list(map())} | error()
  def search_jql_all(client, params) do
    issues =
      search_jql_stream(client, params)
      |> Stream.flat_map(fn page -> page["issues"] end)
      |> Enum.to_list()

    {:ok, issues}
  end
end
