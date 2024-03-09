defmodule Jiraffe.PaginationTest do
  @moduledoc false
  use ExUnit.Case
  doctest Jiraffe

  import Tesla.Mock

  use Jiraffe.Pagination

  def page(client, params) do
    case Jiraffe.get(client, "/test", query: params) do
      {:ok, %{body: body}} ->
        values = Map.get(body, "values", [])

        {:ok,
         %{
           start_at: Map.get(body, "startAt", 0),
           max_results: Map.get(body, "maxResults", Enum.count(values)),
           is_last: Map.get(body, "isLast", Enum.empty?(values)),
           total: Map.get(body, "total", 0),
           values: values
         }}

      {:error, error} ->
        {:error, error}
    end
  end

  describe "stream/2" do
    setup do
      client = Jiraffe.client("https://example.atlassian.net", "a-token")

      mock(fn
        %{
          url: "https://example.atlassian.net/test",
          query: [start_at: 0, max_results: 1]
        } ->
          json(
            %{
              startAt: 0,
              maxResults: 1,
              total: 2,
              values: ["Page 1: A", "Page 1: B"]
            },
            status: 200
          )

        %{
          url: "https://example.atlassian.net/test",
          query: [start_at: 1, max_results: 1]
        } ->
          json(
            %{
              startAt: 1,
              maxResults: 1,
              isLast: true,
              total: 2,
              values: ["Page 2: A", "Page 2: B"]
            },
            status: 200
          )

        %{
          url: "https://example.atlassian.net/test",
          query: [start_at: 0, max_results: 1, no_info: true]
        } ->
          json(
            %{
              values: ["Page 1: A", "Page 1: B"]
            },
            status: 200
          )

        %{url: "https://example.atlassian.net/test"} ->
          json(%{foo: "bar"}, status: 200)
      end)

      {:ok, client: client}
    end

    test "returns a stream of pages", %{client: client} do
      assert [
               %{
                 is_last: false,
                 max_results: 1,
                 start_at: 0,
                 total: 2,
                 values: ["Page 1: A", "Page 1: B"]
               },
               %{
                 is_last: true,
                 max_results: 1,
                 start_at: 1,
                 total: 2,
                 values: ["Page 2: A", "Page 2: B"]
               }
             ] ==
               stream(client, max_results: 1)
               |> Enum.to_list()
    end

    test "returns a page with no values if result has no pagination info", %{client: client} do
      assert [
               %{
                 is_last: true,
                 max_results: 0,
                 start_at: 0,
                 total: 0,
                 values: []
               }
             ] ==
               stream(client, no_info: true)
               |> Enum.to_list()
    end
  end
end
