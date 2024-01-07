defmodule Jiraffe.IssuesTest do
  @moduledoc false
  use ExUnit.Case
  doctest Jiraffe.Issues

  import Tesla.Mock

  @issue %{
    id: "10002",
    self: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
    key: "ED-1",
    fields: %{
      summary: "Foo",
      description: "Bar"
    }
  }

  describe "get/3" do
    setup do
      mock(fn
        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/WRONG-STATUS",
          query: []
        } ->
          json(%{}, status: 400)

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
          query: []
        } ->
          json(@issue, status: 200)

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
          query: [expand: "names,schema", properties: ["prop1", "prop2"]]
        } ->
          json(@issue, status: 200)

        _ ->
          %Tesla.Error{reason: :something_went_wrong}
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "returns the issue with the given ID", %{client: client} do
      assert {:ok,
              %{
                "fields" => %{"description" => "Bar", "summary" => "Foo"},
                "id" => "10002",
                "key" => "ED-1",
                "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002"
              }} ==
               Jiraffe.Issues.get(client, "10002")
    end

    test "returns the issue with the given ID when given additional params", %{client: client} do
      assert {:ok,
              %{
                "fields" => %{"description" => "Bar", "summary" => "Foo"},
                "id" => "10002",
                "key" => "ED-1",
                "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002"
              }} ==
               Jiraffe.Issues.get(client, "10002",
                 expand: "names,schema",
                 properties: ["prop1", "prop2"]
               )
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :unexpected_status}} =
               Jiraffe.Issues.get(client, "WRONG-STATUS")
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issues.get(client, "ERROR")
    end
  end

  describe "bulk_create/2" do
    setup do
      mock(fn
        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body:
            "{\"issueUpdates\":[{\"fields\":{\"description\":\"Bar\",\"project\":{\"key\":\"EX\"},\"summary\":\"Foo\",\"issuetype\":{\"name\":\"Bug\"}}}]}"
        } ->
          json(
            %{
              issues: [
                %{
                  id: "10002",
                  self: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
                  key: "EX-1",
                  fields: %{
                    summary: "Foo",
                    description: "Bar"
                  }
                }
              ],
              errors: []
            },
            status: 201
          )

        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body: "{}"
        } ->
          json(
            %{
              issues: [],
              errors: [
                %{
                  status: 400,
                  elementErrors: %{
                    errorMessages: [],
                    errors: %{
                      issuetype: "The issue type selected is invalid.",
                      project: "Sub-tasks must be created in the same project as the parent."
                    }
                  },
                  failedElementNumber: 0
                }
              ]
            },
            status: 400
          )

        _ ->
          %Tesla.Error{reason: :something_went_wrong}
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "creates issues", %{client: client} do
      assert {:ok,
              %{
                "errors" => [],
                "issues" => [
                  %{
                    "fields" => %{"description" => "Bar", "summary" => "Foo"},
                    "id" => "10002",
                    "key" => "EX-1",
                    "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002"
                  }
                ]
              }} ==
               Jiraffe.Issues.bulk_create(
                 client,
                 %{
                   issueUpdates: [
                     %{
                       fields: %{
                         project: %{
                           key: "EX"
                         },
                         summary: "Foo",
                         description: "Bar",
                         issuetype: %{
                           name: "Bug"
                         }
                       }
                     }
                   ]
                 }
               )
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_create_issues}} =
               Jiraffe.Issues.bulk_create(client, %{})
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issues.bulk_create(client, %{raise: true})
    end
  end
end
