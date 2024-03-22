defmodule Jiraffe.Agile.Issue.RankTest do
  @moduledoc false

  use Jiraffe.Support.TestCase

  setup do
    mock(fn
      %{
        method: :put,
        url: "https://your-domain.atlassian.net/rest/agile/1.0/issue/rank",
        body: %{
          issues: ["B", "C"],
          rankAfterIssue: "A",
          rankCustomFieldId: 42
        }
      } ->
        %Tesla.Env{status: 204}

      %{
        method: :put,
        url: "https://your-domain.atlassian.net/rest/agile/1.0/issue/rank",
        body: %{
          issues: ["B", "C"],
          rankCustomFieldId: 42,
          rankBeforeIssue: "A"
        }
      } ->
        %Tesla.Env{status: 204}

      %{
        method: :put,
        url: "https://your-domain.atlassian.net/rest/agile/1.0/issue/rank",
        body: %{
          issues: ["B", "C"],
          rankAfterIssue: "A"
        }
      } ->
        %Tesla.Env{status: 204}

      %{
        method: :put,
        url: "https://your-domain.atlassian.net/rest/agile/1.0/issue/rank",
        body: %{
          issues: ["B", "C"],
          rankBeforeIssue: "A"
        }
      } ->
        %Tesla.Env{status: 204}

      %{
        method: :put,
        url: "https://your-domain.atlassian.net/rest/agile/1.0/issue/rank"
      } ->
        json(
          %{},
          status: 400
        )

      unexpected ->
        raise "Unexpected request: #{inspect(unexpected)}"
    end)

    client = Jiraffe.Client.new("https://your-domain.atlassian.net", "a-token")

    {:ok, client: client}
  end

  describe "rank_after_issue/3" do
    test "makes a request with the correct parameters", %{client: client} do
      assert {:ok, _} =
               Jiraffe.Agile.Issue.rank_after_issue(
                 client,
                 "A",
                 [
                   "B",
                   "C"
                 ]
               )
    end
  end

  describe "rank_after_issue/4" do
    test "makes a request with the correct parameters", %{client: client} do
      assert {:ok, _} =
               Jiraffe.Agile.Issue.rank_after_issue(
                 client,
                 "A",
                 [
                   "B",
                   "C"
                 ],
                 rank_custom_field_id: 42
               )
    end

    test "returns error when Jira returns error", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_rank_issues}} =
               Jiraffe.Agile.Issue.rank_after_issue(
                 client,
                 "will-fail",
                 [],
                 rank_custom_field_id: 42
               )
    end
  end

  describe "rank_before_issue/3" do
    test "makes a request with the correct parameters", %{client: client} do
      assert {:ok, _} =
               Jiraffe.Agile.Issue.rank_before_issue(
                 client,
                 "A",
                 [
                   "B",
                   "C"
                 ]
               )
    end
  end

  describe "rank_before_issue/4" do
    test "makes a request with the correct parameters", %{client: client} do
      assert {:ok, _} =
               Jiraffe.Agile.Issue.rank_before_issue(
                 client,
                 "A",
                 [
                   "B",
                   "C"
                 ],
                 rank_custom_field_id: 42
               )
    end

    test "returns error when Jira returns error", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_rank_issues}} =
               Jiraffe.Agile.Issue.rank_before_issue(
                 client,
                 "will-fail",
                 [],
                 rank_custom_field_id: 42
               )
    end
  end
end
