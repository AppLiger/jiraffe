defmodule Jiraffe.Issue.JqlSearchTest do
  @moduledoc false
  use ExUnit.Case
  import Tesla.Mock

  alias Jiraffe.ResultsPage

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
        query: [jql: "non-acceptable-query"]
      } ->
        json(%{}, status: 400)

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [maxResults: 1, jql: "project = EX"]
      } ->
        json(%{
          startAt: 0,
          maxResults: 1,
          total: 2,
          isLast: false,
          issues: [Enum.at(@issues, 0)],
          names: %{
            "summary" => "Summary"
          }
        })

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [maxResults: 1, startAt: 0, jql: "project = EX"]
      } ->
        json(%{
          startAt: 0,
          maxResults: 1,
          isLast: false,
          total: 2,
          issues: [Enum.at(@issues, 0)],
          names: %{
            "summary" => "Summary"
          }
        })

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [maxResults: 1, startAt: 1, jql: "project = EX"]
      } ->
        json(%{
          startAt: 1,
          maxResults: 1,
          isLast: true,
          total: 2,
          issues: [Enum.at(@issues, 1)],
          names: %{
            "description" => "Description"
          }
        })

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/search",
        query: [jql: "raise"]
      } ->
        %Tesla.Error{reason: :something_went_wrong}

      unexpected ->
        raise "Unexpected request: #{inspect(unexpected)}"
    end)

    client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

    {:ok, client: client}
  end

  describe "search_jql/3" do
    test "returns a page issues found using the JQL query", %{client: client} do
      assert {:ok,
              %ResultsPage{
                start_at: 0,
                max_results: 1,
                is_last: false,
                total: 2,
                values: %{
                  issues: [
                    %Jiraffe.Issue{
                      id: "10002",
                      self: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
                      key: "EX-1",
                      fields: %{
                        "summary" => "Foo",
                        "description" => "Bar"
                      }
                    }
                  ],
                  names: %{"summary" => "Summary"},
                  schema: %{}
                }
              }} ==
               Jiraffe.Issue.jql_search(client, jql: "project = EX", max_results: 1)
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :unexpected_status}} =
               Jiraffe.Issue.jql_search(client,
                 jql: "non-acceptable-query"
               )
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issue.jql_search(client, jql: "raise")
    end
  end

  describe "search_jql_all/2" do
    test "returns all issues found using the JQL query", %{client: client} do
      assert {:ok,
              %{
                names: %{
                  "description" => "Description",
                  "summary" => "Summary"
                },
                issues: [
                  %Jiraffe.Issue{
                    edit_meta: %Jiraffe.Issue.EditMetadata{fields: %{}},
                    fields: %{"description" => "Bar", "summary" => "Foo"},
                    id: "10002",
                    key: "EX-1",
                    self: "https://your-domain.atlassian.net/rest/api/2/issue/10002"
                  },
                  %Jiraffe.Issue{
                    edit_meta: %Jiraffe.Issue.EditMetadata{fields: %{}},
                    fields: %{"description" => "Qux", "summary" => "Baz"},
                    id: "10003",
                    key: "EX-2",
                    self: "https://your-domain.atlassian.net/rest/api/2/issue/10003"
                  }
                ],
                schema: %{}
              }} ==
               Jiraffe.Issue.jql_search_all(client, jql: "project = EX", max_results: 1)
    end
  end

  describe "search_jql_stream/3" do
    test "returns stream of all issues found using the JQL query", %{client: client} do
      assert [
               %ResultsPage{
                 is_last: false,
                 values: %{
                   names: %{
                     "summary" => "Summary"
                   },
                   schema: %{},
                   issues: [
                     %Jiraffe.Issue{
                       fields: %{"description" => "Bar", "summary" => "Foo"},
                       id: "10002",
                       key: "EX-1",
                       self: "https://your-domain.atlassian.net/rest/api/2/issue/10002"
                     }
                   ]
                 },
                 max_results: 1,
                 start_at: 0,
                 total: 2
               },
               %ResultsPage{
                 is_last: true,
                 values: %{
                   names: %{
                     "description" => "Description"
                   },
                   schema: %{},
                   issues: [
                     %Jiraffe.Issue{
                       fields: %{"description" => "Qux", "summary" => "Baz"},
                       id: "10003",
                       key: "EX-2",
                       self: "https://your-domain.atlassian.net/rest/api/2/issue/10003"
                     }
                   ]
                 },
                 max_results: 1,
                 start_at: 1,
                 total: 2
               }
             ] ==
               Jiraffe.Issue.jql_search_stream(client, jql: "project = EX", max_results: 1)
               |> Enum.to_list()
    end
  end
end
