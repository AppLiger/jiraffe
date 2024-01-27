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

  describe "search_jql/3" do
    test "returns issues found using the JQL query", %{client: client} do
      assert {:ok,
              %{
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
              }} ==
               Jiraffe.Issue.Search.search_jql(client, jql: "project = EX", maxResults: 1)
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :unexpected_status}} =
               Jiraffe.Issue.Search.search_jql(client,
                 jql: "non-acceptable-query",
                 maxResults: 1
               )
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issue.Search.search_jql(client, raise: true)
    end
  end

  describe "search_jql_all/2" do
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
               Jiraffe.Issue.Search.search_jql_all(client, jql: "project = EX", maxResults: 1)
    end
  end

  describe "search_jql_stream/3" do
    test "returns stream of all issues found using the JQL query", %{client: client} do
      assert [
               %{
                 "isLast" => false,
                 "issues" => [
                   %{
                     "fields" => %{"description" => "Bar", "summary" => "Foo"},
                     "id" => "10002",
                     "key" => "EX-1",
                     "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002"
                   }
                 ],
                 "maxResults" => 1,
                 "startAt" => 0,
                 "total" => 2
               },
               %{
                 "isLast" => true,
                 "issues" => [
                   %{
                     "fields" => %{"description" => "Qux", "summary" => "Baz"},
                     "id" => "10003",
                     "key" => "EX-2",
                     "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10003"
                   }
                 ],
                 "maxResults" => 1,
                 "startAt" => 1,
                 "total" => 2
               }
             ] ==
               Jiraffe.Issue.Search.search_jql_stream(client, jql: "project = EX", maxResults: 1)
               |> Enum.to_list()
    end
  end
end
