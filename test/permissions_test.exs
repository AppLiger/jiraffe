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
          query: %{permissions: "EDIT_ISSUES", projectId: "42"}
        } ->
          json(jira_response_body("/api/2/mypermissions"), status: 200)

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/mypermissions"
        } ->
          %Tesla.Env{status: 400}
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
               Jiraffe.Permissions.my_permissions(client)
    end
  end
end
