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

  describe "bulk_create/2" do
    setup do
      mock(fn
        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body:
            "{\"issueUpdates\":[{\"fields\":{\"description\":\"Bar\",\"project\":{\"key\":\"EX\"},\"summary\":\"Foo\",\"issuetype\":{\"name\":\"Bug\"}}}]}"
        } ->
          json(
            jira_response_body("/api/2/issue/bulk"),
            status: 201
          )

        %{
          method: :post,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/bulk",
          body: "{}"
        } ->
          json(
            jira_response_body("/api/2/issue/bulk.error"),
            status: 400
          )

        _ ->
          %Tesla.Error{reason: :something_went_wrong}
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "creates issues", %{client: client} do
      assert {:ok,
              %{
                "errors" => [],
                "issues" => [
                  %{
                    "fields" => %{"description" => "Bar", "summary" => "Foo"},
                    "id" => "10002",
                    "key" => "EX-1",
                    "self" => "https://your-domain.atlassian.net/rest/api/2/issue/10002"
                  }
                ]
              }} ==
               Jiraffe.Issue.bulk_create(
                 client,
                 %{
                   issueUpdates: [
                     %{
                       fields: %{
                         project: %{
                           key: "EX"
                         },
                         summary: "Foo",
                         description: "Bar",
                         issuetype: %{
                           name: "Bug"
                         }
                       }
                     }
                   ]
                 }
               )
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_create_issues}} =
               Jiraffe.Issue.bulk_create(client, %{})
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issue.bulk_create(client, %{raise: true})
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

  describe "get_edit_issue_metadata/2" do
    setup do
      mock(fn
        %{
          method: :get,
          url: "https://your-domain.atlassian.net/rest/api/2/issue/10002/editmeta",
          query: []
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
              %{
                "expand" => "projects.issuetypes.fields",
                "projects" => [
                  %{
                    "expand" => "issuetypes.fields",
                    "issuetypes" => [
                      %{
                        "fields" => %{
                          "description" => %{
                            "hasDefaultValue" => false,
                            "key" => "description",
                            "name" => "Description",
                            "operations" => ["set"],
                            "required" => false,
                            "schema" => %{
                              "system" => "description",
                              "type" => "string"
                            }
                          },
                          "summary" => %{
                            "hasDefaultValue" => false,
                            "key" => "summary",
                            "name" => "Summary",
                            "operations" => ["set"],
                            "required" => true,
                            "schema" => %{
                              "system" => "summary",
                              "type" => "string"
                            }
                          }
                        },
                        "id" => "10000",
                        "name" => "Bug",
                        "self" => "https://your-domain.atlassian.net/rest/api/2/issuetype/10000"
                      }
                    ],
                    "self" => "https://your-domain.atlassian.net/rest/api/2/project/10000"
                  }
                ]
              }} ==
               Jiraffe.Issue.get_edit_issue_metadata(client, "10002")
    end

    test "returns error when gets unexpected status code", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_get_edit_issue_metadata}} =
               Jiraffe.Issue.get_edit_issue_metadata(client, "WRONG-STATUS")
    end

    test "returns error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} = Jiraffe.Issue.get_edit_issue_metadata(client, "ERROR")
    end
  end

  describe "get_create_issue_metadata/2" do
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
          query: [return: 404]
        } ->
          json(
            %{},
            status: 404
          )

        _ ->
          %Tesla.Error{reason: :something_went_wrong}
      end)

      client = Jiraffe.client("https://your-domain.atlassian.net", "a-token")

      {:ok, client: client}
    end

    test "returns details of projects, issue types within projects for each issue type for the user",
         %{client: client} do
      assert {:ok,
              %{
                "projects" => [
                  %{
                    "issuetypes" => [
                      %{
                        "id" => "10000",
                        "name" => "Epic",
                        "self" => "https://your-domain.atlassian.net/rest/api/3/issuetype/10000",
                        "description" =>
                          "A big user story that needs to be broken down. Created by Jira Software - do not edit or delete.",
                        "iconUrl" =>
                          "https://your-domain.atlassian.net/images/icons/issuetypes/epic.svg",
                        "subtask" => false,
                        "untranslatedName" => "Epic"
                      },
                      %{
                        "description" =>
                          "Stories track functionality or features expressed as user goals.",
                        "iconUrl" =>
                          "https://your-domain.atlassian.net/images/icons/issuetypes/story.svg",
                        "id" => "10001",
                        "name" => "Story",
                        "self" => "https://your-domain.atlassian.net/rest/api/3/issuetype/10001",
                        "subtask" => false,
                        "untranslatedName" => "Story"
                      }
                    ],
                    "self" => "https://your-domain.atlassian.net/rest/api/3/project/10004",
                    "avatarUrls" => %{
                      "16x16" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?size=xsmall&s=xsmall&pid=10004&avatarId=10404",
                      "24x24" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?size=small&s=small&pid=10004&avatarId=10404",
                      "32x32" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?size=medium&s=medium&pid=10004&avatarId=10404",
                      "48x48" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?pid=10004&avatarId=10404"
                    },
                    "id" => "10004",
                    "key" => "ESD",
                    "name" => "External service desk"
                  }
                ]
              }} ==
               Jiraffe.Issue.get_create_issue_metadata(client, [])
    end

    test "returns details of projects, issue types within projects, and (requested) create screen fields for each issue type for the user when given additional params",
         %{client: client} do
      assert {:ok,
              %{
                "expand" => "projects",
                "projects" => [
                  %{
                    "expand" => "issuetypes",
                    "issuetypes" => [
                      %{
                        "fields" => %{
                          "description" => %{
                            "hasDefaultValue" => false,
                            "key" => "description",
                            "name" => "Description",
                            "operations" => ["set"],
                            "required" => false,
                            "schema" => %{
                              "system" => "description",
                              "type" => "string"
                            }
                          },
                          "summary" => %{
                            "hasDefaultValue" => false,
                            "key" => "summary",
                            "name" => "Summary",
                            "operations" => ["set"],
                            "required" => true,
                            "schema" => %{
                              "system" => "summary",
                              "type" => "string"
                            }
                          }
                        },
                        "id" => "10000",
                        "name" => "Epic",
                        "self" => "https://your-domain.atlassian.net/rest/api/3/issuetype/10000",
                        "description" =>
                          "A big user story that needs to be broken down. Created by Jira Software - do not edit or delete.",
                        "expand" => "fields",
                        "iconUrl" =>
                          "https://your-domain.atlassian.net/images/icons/issuetypes/epic.svg",
                        "subtask" => false,
                        "untranslatedName" => "Epic"
                      }
                    ],
                    "self" => "https://your-domain.atlassian.net/rest/api/3/project/10004",
                    "avatarUrls" => %{
                      "16x16" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?size=xsmall&s=xsmall&pid=10004&avatarId=10404",
                      "24x24" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?size=small&s=small&pid=10004&avatarId=10404",
                      "32x32" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?size=medium&s=medium&pid=10004&avatarId=10404",
                      "48x48" =>
                        "https://your-domain.atlassian.net/secure/projectavatar?pid=10004&avatarId=10404"
                    },
                    "id" => "10004",
                    "key" => "ESD",
                    "name" => "External service desk"
                  }
                ]
              }} ==
               Jiraffe.Issue.get_create_issue_metadata(client,
                 expand: "projects.issuetypes.fields"
               )
    end

    test "returns an error when gets unexpected status code (not 200)", %{client: client} do
      assert {:error, %Jiraffe.Error{reason: :cannot_get_crete_meta}} =
               Jiraffe.Issue.get_create_issue_metadata(client, return: 404)
    end

    test "returns an error when gets error", %{client: client} do
      assert {:error, %Jiraffe.Error{}} =
               Jiraffe.Issue.get_create_issue_metadata(client, raise: true)
    end
  end
end
