defmodule Jiraffe.Issue.JqlSearch do
  @moduledoc false

  alias Jiraffe.{Issue, Error}
  use Jiraffe.Pagination

  @impl Jiraffe.Pagination
  @spec page(
          Jiraffe.client(),
          params :: Issue.jql_search_params()
        ) ::
          {:ok, Jiraffe.ResultsPage.t()} | {:error, Error.t()}
  def page(client, params) do
    params =
      [
        expand: Keyword.get(params, :expand),
        fields: Keyword.get(params, :fields),
        fieldsByKey: Keyword.get(params, :fields_by_key),
        maxResults: Keyword.get(params, :max_results),
        properties: Keyword.get(params, :properties),
        startAt: Keyword.get(params, :start_at),
        validateQuery: Keyword.get(params, :validate_query),
        jql: Keyword.get(params, :jql)
      ]
      |> Keyword.reject(fn {_, v} -> is_nil(v) end)

    case Jiraffe.get(client, "/rest/api/2/search", query: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok,
         %Jiraffe.ResultsPage{
           start_at: Map.get(body, "startAt", 0),
           max_results: Map.get(body, "maxResults", 50),
           is_last: Map.get(body, "isLast", true),
           total: Map.get(body, "total", 0),
           values: %{
             issues: Map.get(body, "issues", []) |> Enum.map(&Issue.new/1),
             names: Map.get(body, "names", %{}),
             schema: Map.get(body, "schema", %{})
           }
         }}

      {:ok, result} ->
        {:error, Error.new(:unexpected_status, result)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end

  @impl Jiraffe.Pagination
  def transform_values(list) do
    list
    |> Enum.reduce(%{issues: [], names: %{}, schema: %{}}, fn v, acc ->
      %{
        issues: acc.issues ++ v.issues,
        names: Map.merge(acc.names, v.names),
        schema: Map.merge(acc.schema, v.schema)
      }
    end)
  end
end
