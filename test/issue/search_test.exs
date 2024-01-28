defmodule Jiraffe.Issue.SearchTest do
  @moduledoc false
  use ExUnit.Case
  import Tesla.Mock
  doctest Jiraffe

  @issues [
    %{
      id: "10002",
      self: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
      key: "EX-1",
      fields: %{
        summary: "Foo",
        description: "Bar"
      }
    },
    %{
      id: "10003",
      self: "https://your-domain.atlassian.net/rest/api/2/issue/10003",
      key: "EX-2",
      fields: %{
        summary: "Baz",
        description: "Qux"
      }
    }
  ]

  setup do
    mock(fn
      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [jql: "non-acceptable-query", maxResults: 1]
      } ->
        json(%{}, status: 400)

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [jql: "project = EX", maxResults: 1]
      } ->
        json(%{
          startAt: 0,
          maxResults: 1,
          total: 2,
          isLast: false,
          issues: [Enum.at(@issues, 0)]
        })

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [jql: "project = EX", startAt: 0, maxResults: 1]
      } ->
        json(%{
          startAt: 0,
          maxResults: 1,
          isLast: false,
          total: 2,
          issues: [Enum.at(@issues, 0)]
        })

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [jql: "project = EX", startAt: 1, maxResults: 1]
      } ->
        json(%{
          startAt: 1,
          maxResults: 1,
          isLast: true,
          total: 2,
          issues: [Enum.at(@issues, 1)]
        })

      _unmatched ->
        %Tesla.Error{reason: :something_went_wrong}
    end)

    client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

    {:ok, client: client}
  end

  describe "search_jql/2" do
    test "returns stream of all issues found using the JQL query", %{client: client} do
      assert {:ok,
              [
                %{
                  "id" => "10002",
                  "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002",
                  "key" => "EX-1",
                  "fields" => %{
                    "summary" => "Foo",
                    "description" => "Bar"
                  }
                },
                %{
                  "id" => "10003",
                  "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10003",
                  "key" => "EX-2",
                  "fields" => %{
                    "summary" => "Baz",
                    "description" => "Qux"
                  }
                }
              ]} ==
               Jiraffe.Issue.Search.search_jql(client, jql: "project = EX", maxResults: 1)
    end
  end

  describe "search_jql_stream/3" do
    test "returns stream of all issues found using the JQL query", %{client: client} do
      assert [
               %{
                 is_last: false,
                 values: [
                   %{
                     "fields" => %{"description" => "Bar", "summary" => "Foo"},
                     "id" => "10002",
                     "key" => "EX-1",
                     "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002"
                   }
                 ],
                 max_results: 1,
                 start_at: 0,
                 total: 2
               },
               %{
                 is_last: true,
                 values: [
                   %{
                     "fields" => %{"description" => "Qux", "summary" => "Baz"},
                     "id" => "10003",
                     "key" => "EX-2",
                     "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10003"
                   }
                 ],
                 max_results: 1,
                 start_at: 1,
                 total: 2
               }
             ] ==
               Jiraffe.Issue.Search.search_jql_stream(client, jql: "project = EX", maxResults: 1)
               |> Enum.to_list()
    end
  end
end
