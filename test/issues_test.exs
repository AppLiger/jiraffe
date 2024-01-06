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
      assert {:ok, @issue} ==
               Jiraffe.Issues.get(client, "10002")
    end

    test "returns the issue with the given ID when given additional params", %{client: client} do
      assert {:ok, @issue} ==
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
end
