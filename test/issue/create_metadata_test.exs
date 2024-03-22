defmodule Jiraffe.Issue.CreateMetadataTest do
  @moduledoc false
  use Jiraffe.Support.TestCase

  describe "get/2" do
    setup do
      mock(fn
        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/createmeta",
          query: []
        } ->
          json(
            jira_response_body("/api/2/issue/createmeta"),
            status: 200
          )

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/createmeta",
          query: [expand: "projects.issuetypes.fields"]
        } ->
          json(
            jira_response_body("/api/2/issue/createmeta.expanded"),
            status: 200
          )

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/createmeta",
          query: [expand: "404"]
        } ->
          json(
            %{},
            status: 404
          )

        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/createmeta",
          query: [expand: "raise"]
        } ->
          %Tesla.Error{reason: :something_went_wrong}

        unmatched ->
          raise "Unexpected request: #{inspect(unmatched)}"
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "returns details of projects, issue types within projects for each issue type for the user",
         %{client: client} do
      assert {:ok,
              %Jiraffe.Issue.CreateMetadata{
                projects: projects
              }} =
               Jiraffe.Issue.get_create_metadata(client, [])

      assert [
               %Jiraffe.Issue.CreateMetadata.Project{
                 avatar_urls: avatar_urls,
                 id: "10004",
                 issue_types: issue_types,
                 key: "ESD",
                 name: "External service desk",
                 self: "https://your-domain.atlassian.net/rest/api/3/project/10004"
               }
             ] = projects

      assert %Jiraffe.Avatar.Url{
               tiny:
                 "https://your-domain.atlassian.net/secure/projectavatar?size=xsmall&s=xsmall&pid=10004&avatarId=10404",
               small:
                 "https://your-domain.atlassian.net/secure/projectavatar?size=small&s=small&pid=10004&avatarId=10404",
               medium:
                 "https://your-domain.atlassian.net/secure/projectavatar?size=medium&s=medium&pid=10004&avatarId=10404",
               large:
                 "https://your-domain.atlassian.net/secure/projectavatar?pid=10004&avatarId=10404"
             } = avatar_urls

      assert [
               %Jiraffe.Issue.CreateMetadata.Project.IssueType{
                 avatar_id: nil,
                 description:
                   "A big user story that needs to be broken down. Created by Jira Software - do not edit or delete.",
                 entity_id: nil,
                 expand: nil,
                 fields: %{},
                 hierarchy_level: 0,
                 icon_url: "https://your-domain.atlassian.net/images/icons/issuetypes/epic.svg",
                 id: "10000",
                 name: "Epic",
                 scope: nil,
                 self: "https://your-domain.atlassian.net/rest/api/3/issuetype/10000",
                 subtask?: false
               },
               %Jiraffe.Issue.CreateMetadata.Project.IssueType{
                 avatar_id: nil,
                 description: "Stories track functionality or features expressed as user goals.",
                 entity_id: nil,
                 expand: nil,
                 fields: %{},
                 hierarchy_level: 0,
                 icon_url: "https://your-domain.atlassian.net/images/icons/issuetypes/story.svg",
                 id: "10001",
                 name: "Story",
                 scope: nil,
                 self: "https://your-domain.atlassian.net/rest/api/3/issuetype/10001",
                 subtask?: false
               }
             ] == issue_types
    end

    test "returns details of projects, issue types within projects, and (requested) create screen fields for each issue type for the user when given additional params",
         %{client: client} do
      assert {:ok,
              %Jiraffe.Issue.CreateMetadata{
                expand: "projects",
                projects: projects
              }} =
               Jiraffe.Issue.get_create_metadata(client,
                 expand: "projects.issuetypes.fields"
               )

      assert [
               %Jiraffe.Issue.CreateMetadata.Project{
                 expand: "issuetypes",
                 self: "https://your-domain.atlassian.net/rest/api/3/project/10004",
                 id: "10004",
                 key: "ESD",
                 name: "External service desk",
                 avatar_urls: %Jiraffe.Avatar.Url{
                   tiny:
                     "https://your-domain.atlassian.net/secure/projectavatar?size=xsmall&s=xsmall&pid=10004&avatarId=10404",
                   small:
                     "https://your-domain.atlassian.net/secure/projectavatar?size=small&s=small&pid=10004&avatarId=10404",
                   medium:
                     "https://your-domain.atlassian.net/secure/projectavatar?size=medium&s=medium&pid=10004&avatarId=10404",
                   large:
                     "https://your-domain.atlassian.net/secure/projectavatar?pid=10004&avatarId=10404"
                 },
                 issue_types: issue_types
               }
             ] = projects

      assert [
               %Jiraffe.Issue.CreateMetadata.Project.IssueType{
                 self: "https://your-domain.atlassian.net/rest/api/3/issuetype/10000",
                 id: "10000",
                 description:
                   "A big user story that needs to be broken down. Created by Jira Software - do not edit or delete.",
                 icon_url: "https://your-domain.atlassian.net/images/icons/issuetypes/epic.svg",
                 name: "Epic",
                 subtask?: false,
                 avatar_id: nil,
                 entity_id: nil,
                 hierarchy_level: 0,
                 scope: nil,
                 expand: "fields",
                 fields: fields
               }
             ] = issue_types

      assert %{
               "description" => %Jiraffe.Issue.Field.Metadata{
                 allowed_values: [],
                 auto_complete_url: nil,
                 configuration: %{},
                 default_value: nil,
                 has_default_value?: false,
                 key: "description",
                 name: "Description",
                 operations: ["set"],
                 required?: false,
                 schema: %Jiraffe.Issue.Field.Metadata.Schema{
                   configuration: %{},
                   custom: "",
                   custom_id: 0,
                   items: nil,
                   system: "description",
                   type: "string"
                 }
               },
               "summary" => %Jiraffe.Issue.Field.Metadata{
                 allowed_values: [],
                 auto_complete_url: nil,
                 configuration: %{},
                 default_value: nil,
                 has_default_value?: false,
                 key: "summary",
                 name: "Summary",
                 operations: ["set"],
                 required?: true,
                 schema: %Jiraffe.Issue.Field.Metadata.Schema{
                   configuration: %{},
                   custom: "",
                   custom_id: 0,
                   items: nil,
                   system: "summary",
                   type: "string"
                 }
               }
             } = fields
    end

    test "returns an error when gets unexpected status code (not 200)", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_get_crete_meta}} =
               Jiraffe.Issue.get_create_metadata(client, expand: "404")
    end

    test "returns an error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} =
               Jiraffe.Issue.get_create_metadata(client, expand: "raise")
    end
  end
end
