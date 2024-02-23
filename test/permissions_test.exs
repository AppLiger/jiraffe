defmodule Jiraffe.PermissionsTest do
  @moduledoc false
  use ExUnit.Case

  import Tesla.Mock
  import JiraffeTest.Support

  describe "get/3" do
    setup do
      mock(fn
        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/mypermissions",
          query: [projectId: "42", permissions: "EDIT_ISSUES"]
        } ->
          json(jira_response_body("/api/2/mypermissions"), status: 200)

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/mypermissions",
          query: [projectId: "fail"]
        } ->
          %Tesla.Env{status: 400}

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/mypermissions",
          query: [projectId: "raise"]
        } ->
          %Tesla.Error{reason: 500}

        unexpected ->
          raise "Unexpected request: #{inspect(unexpected)}"
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "returns the issue with the given ID", %{client: client} do
      assert {:ok,
              %{
                "EDIT_ISSUES" => %Jiraffe.Permissions.UserPermission{
                  id: "12",
                  key: "EDIT_ISSUES",
                  name: "Edit Issues",
                  type: "PROJECT",
                  description: "Ability to edit issues.",
                  have_permission: true
                }
              }} ==
               Jiraffe.Permissions.my_permissions(client,
                 project_id: "42",
                 permissions: "EDIT_ISSUES"
               )
    end

    test "returns an error when the request fails", %{client: client} do
      assert {:error,
              %Jiraffe.Error{
                reason: :cannot_get_my_permissions,
                details: %Tesla.Env{status: 400}
              }} ==
               Jiraffe.Permissions.my_permissions(client, project_id: "fail")
    end

    test "returns an error when gets error", %{client: client} do
      assert {:error,
              %Jiraffe.Error{
                reason: :cannot_get_my_permissions,
                details: %Tesla.Error{reason: 500}
              }} ==
               Jiraffe.Permissions.my_permissions(client, project_id: "raise")
    end
  end
end
