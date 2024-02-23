defmodule Jiraffe.Issue.LinkTest do
  @moduledoc false
  use ExUnit.Case

  import Tesla.Mock

  describe "link/2" do
    setup do
      mock(fn
        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issueLink",
          body:
            "{\"type\":{\"id\":\"42\"},\"inwardIssue\":{\"id\":\"10001\"},\"outwardIssue\":{\"id\":\"10002\"}}"
        } ->
          json(
            %{},
            status: 201
          )

        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issueLink",
          body:
            "{\"type\":{\"id\":\"fail\"},\"inwardIssue\":{\"id\":\"10001\"},\"outwardIssue\":{\"id\":\"10002\"}}"
        } ->
          json(
            %{},
            status: 400
          )

        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issueLink",
          body:
            "{\"type\":{\"id\":\"raise\"},\"inwardIssue\":{\"id\":\"10001\"},\"outwardIssue\":{\"id\":\"10002\"}}"
        } ->
          %Tesla.Error{reason: :something_went_wrong}

        unexpected ->
          raise "Unexpected request: #{inspect(unexpected)}"
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "links issues", %{client: client} do
      assert {:ok, %{}} ==
               Jiraffe.Issue.link(
                 client,
                 type_id: "42",
                 inward_issue_id: "10001",
                 outward_issue_id: "10002"
               )
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_create_issue_link}} =
               Jiraffe.Issue.link(
                 client,
                 type_id: "fail",
                 inward_issue_id: "10001",
                 outward_issue_id: "10002"
               )
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} =
               Jiraffe.Issue.link(
                 client,
                 type_id: "raise",
                 inward_issue_id: "10001",
                 outward_issue_id: "10002"
               )
    end
  end
end
