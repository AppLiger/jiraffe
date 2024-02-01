defmodule Jiraffe.Issue.UpdateTest do
  @moduledoc false
  use ExUnit.Case

  import Tesla.Mock

  describe "update/2" do
    setup do
      mock(fn
        %{
          method: :put,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/10002",
          body: "{\"fields\":{\"description\":\"Bar\",\"summary\":\"Foo\"}}",
          query: [
            notifyUsers: true,
            overrideScreenSecurity: true,
            overrideEditableFlag: true,
            returnIssue: true,
            expand: "names,schema"
          ]
        } ->
          json(%{}, status: 204)

        %{
          method: :put,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/WRONG-STATUS",
          body: "{\"fields\":{\"description\":\"Bar\",\"summary\":\"Foo\"}}"
        } ->
          json(%{}, status: 400)

        %{
          method: :put,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/ERROR"
        } ->
          %Tesla.Error{reason: :something_went_wrong}

        unexpected ->
          raise "Unexpected request: #{inspect(unexpected)}"
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
                 },
                 notify_users: true,
                 override_screen_security: true,
                 override_editable_flag: true,
                 return_issue: true,
                 expand: "names,schema"
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
