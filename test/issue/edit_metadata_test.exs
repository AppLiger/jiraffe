defmodule Jiraffe.Issue.EditMetadataTest do
  @moduledoc false
  use ExUnit.Case

  import Tesla.Mock
  import JiraffeTest.Support

  describe "get/2" do
    setup do
      mock(fn
        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/10002/editmeta",
          query: [overrideScreenSecurity: true]
        } ->
          json(
            jira_response_body("/api/2/issue/10002/editmeta"),
            status: 200
          )

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/WRONG-STATUS/editmeta",
          query: []
        } ->
          json(%{}, status: 400)

        _ ->
          %Tesla.Error{reason: :something_went_wrong}
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "returns the edit screen fields for an issue that are visible to and editable by the user",
         %{client: client} do
      assert {:ok,
              %Jiraffe.Issue.EditMetadata{
                fields: fields
              }} =
               Jiraffe.Issue.get_edit_metadata(client, "10002", override_screen_security: true)

      assert %{
               "description" => %Jiraffe.Issue.Field.Metadata{
                 has_default_value?: false,
                 key: "description",
                 name: "Description",
                 operations: ["set"],
                 required?: false,
                 schema: %Jiraffe.Issue.Field.Metadata.Schema{
                   system: "description",
                   type: "string"
                 }
               },
               "summary" => %Jiraffe.Issue.Field.Metadata{
                 has_default_value?: false,
                 key: "summary",
                 name: "Summary",
                 operations: ["set"],
                 required?: true,
                 schema: %Jiraffe.Issue.Field.Metadata.Schema{
                   system: "summary",
                   type: "string"
                 }
               }
             } = fields
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_get_edit_issue_metadata}} =
               Jiraffe.Issue.get_edit_metadata(client, "WRONG-STATUS")
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issue.get_edit_metadata(client, "ERROR")
    end
  end
end
