defmodule Jiraffe.Issue.BulkCreateTest do
  @moduledoc false
  use Jiraffe.Support.TestCase

  describe "bulk_create/2" do
    setup do
      mock(fn
        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body: %{
            issueUpdates: [
              %{
                fields: %{
                  summary: "Foo",
                  description: "Bar",
                  project: %{key: "EX"},
                  issuetype: %{name: "Bug"}
                }
              }
            ]
          }
        } ->
          json(
            jira_response_body("/api/2/issue/bulk"),
            status: 201
          )

        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body: %{
            issueUpdates: [
              %{fields: %{status: 400}}
            ]
          }
        } ->
          json(
            jira_response_body("/api/2/issue/bulk.error"),
            status: 400
          )

        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body: %{
            issueUpdates: [
              %{fields: %{raise: true}}
            ]
          }
        } ->
          %Tesla.Error{reason: :something_went_wrong}

        unexpected ->
          raise "Unexpected request: #{inspect(unexpected)}"
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "creates issues", %{client: client} do
      assert {:ok,
              %Jiraffe.Issue.BulkCreateResult{
                errors: [],
                issues: created_issues
              }} =
               Jiraffe.Issue.bulk_create(
                 client,
                 [
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
               )

      assert [
               %Jiraffe.Issue.Created{
                 id: "10002",
                 key: "EX-1",
                 self: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
                 transition: nil
               }
             ] = created_issues
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_create_issues}} =
               Jiraffe.Issue.bulk_create(client, [%{fields: %{status: 400}}])
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} =
               Jiraffe.Issue.bulk_create(client, [%{fields: %{raise: true}}])
    end
  end
end
