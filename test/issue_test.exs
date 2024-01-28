defmodule Jiraffe.IssueTest do
  @moduledoc false
  use ExUnit.Case
  doctest Jiraffe.Issue

  import Tesla.Mock
  import JiraffeTest.Support

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
          json(jira_response_body("/api/2/issue/10002"), status: 200)

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
          query: [expand: "names,schema", properties: ["prop1", "prop2"]]
        } ->
          json(jira_response_body("/api/2/issue/10002"), status: 200)

        _ ->
          %Tesla.Error{reason: :something_went_wrong}
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "returns the issue with the given ID", %{client: client} do
      assert {:ok,
              %Jiraffe.Issue{
                id: "10002",
                key: "ED-1",
                self: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
                fields: %{"description" => "Bar", "summary" => "Foo"}
              }} ==
               Jiraffe.Issue.get(client, "10002")
    end

    test "returns the issue with the given ID when given additional params", %{client: client} do
      assert {:ok,
              %Jiraffe.Issue{
                id: "10002",
                key: "ED-1",
                self: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
                fields: %{"description" => "Bar", "summary" => "Foo"}
              }} ==
               Jiraffe.Issue.get(client, "10002",
                 expand: "names,schema",
                 properties: ["prop1", "prop2"]
               )
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :unexpected_status}} =
               Jiraffe.Issue.get(client, "WRONG-STATUS")
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issue.get(client, "ERROR")
    end
  end

  describe "update/2" do
    setup do
      mock(fn
        %{
          method: :put,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
          body: "{\"fields\":{\"description\":\"Bar\",\"summary\":\"Foo\"}}"
        } ->
          json(%{}, status: 204)

        %{
          method: :put,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/WRONG-STATUS",
          body: "{\"fields\":{\"description\":\"Bar\",\"summary\":\"Foo\"}}"
        } ->
          json(%{}, status: 400)

        _ ->
          %Tesla.Error{reason: :something_went_wrong}
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "updates an issue", %{client: client} do
      assert {:ok, %{id: "10002"}} ==
               Jiraffe.Issue.update(
                 client,
                 "10002",
                 %{
                   fields: %{
                     summary: "Foo",
                     description: "Bar"
                   }
                 }
               )
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_update_issue}} =
               Jiraffe.Issue.update(
                 client,
                 "WRONG-STATUS",
                 %{
                   fields: %{
                     summary: "Foo",
                     description: "Bar"
                   }
                 }
               )
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} =
               Jiraffe.Issue.update(
                 client,
                 "ERROR",
                 %{
                   fields: %{
                     summary: "Foo",
                     description: "Bar"
                   }
                 }
               )
    end
  end
end
