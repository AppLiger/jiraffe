defmodule Jiraffe.Issue.BulkCreateTest do
  @moduledoc false
  use ExUnit.Case

  import Tesla.Mock
  import JiraffeTest.Support

  describe "create/2" do
    setup do
      mock(fn
        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body:
            "{\"issueUpdates\":[{\"fields\":{\"description\":\"Bar\",\"project\":{\"key\":\"EX\"},\"summary\":\"Foo\",\"issuetype\":{\"name\":\"Bug\"}}}]}"
        } ->
          json(
            jira_response_body("/api/2/issue/bulk"),
            status: 201
          )

        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body: "{}"
        } ->
          json(
            jira_response_body("/api/2/issue/bulk.error"),
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
              %Jiraffe.Issue.BulkCreate{
                errors: [],
                issues: created_issues
              }} =
               Jiraffe.Issue.BulkCreate.create(
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
               Jiraffe.Issue.BulkCreate.create(client, %{})
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issue.BulkCreate.create(client, %{raise: true})
    end
  end
end
