defmodule Jiraffe.Issue.Search do
  @moduledoc """
  This resource represents various ways to search for issues.
  Use it to search for issues with a JQL query and find issues to populate an issue picker.
  """
  alias Jiraffe.{Client, Error}

  @type t() :: map()
  @type error() :: {:error, Error.t()}

  use Jiraffe.Pagination,
    naming: [[page_fn: :search_page, stream: :search_jql_stream, all: :search_jql]]

  @doc """
  Searches for issues using JQL.
  Returns a page of issues found using the JQL query.

  ## Examples:
      iex> Jiraffe.Issue.Search.search_page(client, jql: "project = EX", maxResults: 1)
      {:ok, %{
        start_at: 0,
        max_results: 2,
        is_last: true,
        total: 2,
        values: [
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
      ]}}
  """
  @spec search_page(
          Client.t(),
          params :: Keyword.t()
        ) ::
          {:ok, map()} | {:error, Error.t()}
  def search_page(client, params) do
    case Jiraffe.get(client, "/rest/api/2/search", query: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok,
         %{
           start_at: Map.get(body, "startAt", 0),
           max_results: Map.get(body, "maxResults", 50),
           is_last: Map.get(body, "isLast", true),
           total: Map.get(body, "total", 0),
           values: Map.get(body, "issues", [])
         }}

      {:ok, result} ->
        {:error, Error.new(:unexpected_status, result)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
