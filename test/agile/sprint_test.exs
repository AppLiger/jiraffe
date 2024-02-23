defmodule Jiraffe.Agile.SprintTest do
  @moduledoc false
  use ExUnit.Case

  import Tesla.Mock
  import JiraffeTest.Support

  setup do
    mock(fn
      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/agile/1.0/sprint/37"
      } ->
        json(
          jira_response_body("agile/1.0/sprint/37"),
          status: 200
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/agile/1.0/sprint/400"
      } ->
        json(
          %{},
          status: 400
        )

      _ ->
        %Tesla.Error{reason: :something_went_wrong}
    end)

    client = Jiraffe.Client.new("https://your-domain.atlassian.net", "a-token")

    {:ok, client: client}
  end

  describe "get/2" do
    test "return first page of users matching the provided criteria",
         %{client: client} do
      assert {:ok,
              %Jiraffe.Agile.Sprint{
                complete_date: "2015-04-20T11:04:00.000+10:00",
                created_date: nil,
                end_date: "2015-04-20T01:22:00.000+10:00",
                goal: "sprint 1 goal",
                id: 37,
                name: "sprint 1",
                origin_board_id: 5,
                self: "https://your-domain.atlassian.net/rest/agile/1.0/sprint/23",
                start_date: "2015-04-11T15:22:00.000+10:00",
                state: "closed"
              }} ==
               Jiraffe.Agile.Sprint.get(client, 37)
    end

    test "returns error when Jira returns error", %{client: client} do
      assert {:error,
              %Jiraffe.Error{
                reason: :cannot_get_sprint
              }} =
               Jiraffe.Agile.Sprint.get(client, 400)
    end
  end
end
