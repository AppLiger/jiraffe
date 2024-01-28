defmodule Jiraffe.UserTest do
  @moduledoc false
  use ExUnit.Case
  doctest Jiraffe.Issue

  import Tesla.Mock
  import JiraffeTest.Support

  setup do
    mock(fn
      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"]]
      } ->
        json(
          jira_response_body("api/2/user/bulk.1"),
          status: 200
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [
          accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"],
          startAt: 0,
          maxResults: 1
        ]
      } ->
        json(
          jira_response_body("api/2/user/bulk.1"),
          status: 200
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [
          accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"],
          startAt: 1,
          maxResults: 1
        ]
      } ->
        json(
          jira_response_body("api/2/user/bulk.2"),
          status: 200
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [startAt: 1, accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"]]
      } ->
        json(
          jira_response_body("api/2/user/bulk.2"),
          status: 200
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [accountId: ["invalid"]]
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

  describe "get_bulk/2" do
    test "return first page of users matching the provided criteria", %{client: client} do
      assert {:ok,
              %{
                is_last: false,
                max_results: 1,
                start_at: 0,
                total: 2,
                values: [
                  %{
                    "accountId" => "5b10a2844c20165700ede21g",
                    "accountType" => "atlassian",
                    "active" => true,
                    "avatarUrls" => %{
                      "16x16" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=16&s=16",
                      "24x24" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=24&s=24",
                      "32x32" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=32&s=32",
                      "48x48" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=48&s=48"
                    },
                    "displayName" => "Mia Krystof",
                    "emailAddress" => "mia@example.com",
                    "self" =>
                      "https://your-domain.atlassian.net/rest/api/2/user?accountId=5b10a2844c20165700ede21g",
                    "timeZone" => "Australia/Sydney"
                  }
                ]
              }} ==
               Jiraffe.User.get_bulk(client,
                 accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"]
               )
    end

    test "returns second page of users matching the provided criteria", %{client: client} do
      assert {:ok,
              %{
                is_last: true,
                max_results: 1,
                start_at: 1,
                total: 2,
                values: [
                  %{
                    "accountId" => "6b10a2844c20165700ede21g",
                    "accountType" => "atlassian",
                    "active" => true,
                    "avatarUrls" => %{
                      "16x16" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=16&s=16",
                      "24x24" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=24&s=24",
                      "32x32" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=32&s=32",
                      "48x48" =>
                        "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=48&s=48"
                    },
                    "displayName" => "Max Krystof",
                    "emailAddress" => "max@example.com",
                    "self" =>
                      "https://your-domain.atlassian.net/rest/api/2/user?accountId=6b10a2844c20165700ede21g",
                    "timeZone" => "Australia/Sydney"
                  }
                ]
              }} ==
               Jiraffe.User.get_bulk(client,
                 startAt: 1,
                 accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"]
               )
    end

    test "returns error when Jira returns error", %{client: client} do
      assert {:error,
              %Jiraffe.Error{
                reason: :cannot_get_users_list,
                details: %{}
              }} ==
               Jiraffe.User.get_bulk(client,
                 accountId: ["invalid"]
               )
    end

    test "returns error when gets error", %{client: client} do
      assert {:error,
              %Jiraffe.Error{
                details: %Tesla.Error{env: nil, stack: [], reason: :something_went_wrong},
                reason: :general
              }} == Jiraffe.User.get_bulk(client, raise: true)
    end
  end

  describe "get_bulk_stream/2" do
    test "returns stream of pages of users matching the provided criteria", %{client: client} do
      assert [
               %{
                 is_last: false,
                 max_results: 1,
                 start_at: 0,
                 total: 2,
                 values: [
                   %{
                     "accountId" => "5b10a2844c20165700ede21g",
                     "accountType" => "atlassian",
                     "active" => true,
                     "avatarUrls" => %{
                       "16x16" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=16&s=16",
                       "24x24" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=24&s=24",
                       "32x32" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=32&s=32",
                       "48x48" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=48&s=48"
                     },
                     "displayName" => "Mia Krystof",
                     "emailAddress" => "mia@example.com",
                     "self" =>
                       "https://your-domain.atlassian.net/rest/api/2/user?accountId=5b10a2844c20165700ede21g",
                     "timeZone" => "Australia/Sydney"
                   }
                 ]
               },
               %{
                 is_last: true,
                 max_results: 1,
                 start_at: 1,
                 total: 2,
                 values: [
                   %{
                     "accountId" => "6b10a2844c20165700ede21g",
                     "accountType" => "atlassian",
                     "active" => true,
                     "avatarUrls" => %{
                       "16x16" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=16&s=16",
                       "24x24" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=24&s=24",
                       "32x32" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=32&s=32",
                       "48x48" =>
                         "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=48&s=48"
                     },
                     "displayName" => "Max Krystof",
                     "emailAddress" => "max@example.com",
                     "self" =>
                       "https://your-domain.atlassian.net/rest/api/2/user?accountId=6b10a2844c20165700ede21g",
                     "timeZone" => "Australia/Sydney"
                   }
                 ]
               }
             ] ==
               Jiraffe.User.get_bulk_stream(client,
                 maxResults: 1,
                 accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"]
               )
               |> Enum.to_list()
    end
  end

  describe "get_bulk_all/2" do
    test "returns all users matching the provided criteria", %{client: client} do
      assert {:ok,
              [
                %{
                  "accountId" => "5b10a2844c20165700ede21g",
                  "accountType" => "atlassian",
                  "active" => true,
                  "avatarUrls" => %{
                    "16x16" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=16&s=16",
                    "24x24" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=24&s=24",
                    "32x32" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=32&s=32",
                    "48x48" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-5.png?size=48&s=48"
                  },
                  "displayName" => "Mia Krystof",
                  "emailAddress" => "mia@example.com",
                  "self" =>
                    "https://your-domain.atlassian.net/rest/api/2/user?accountId=5b10a2844c20165700ede21g",
                  "timeZone" => "Australia/Sydney"
                },
                %{
                  "accountId" => "6b10a2844c20165700ede21g",
                  "accountType" => "atlassian",
                  "active" => true,
                  "avatarUrls" => %{
                    "16x16" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=16&s=16",
                    "24x24" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=24&s=24",
                    "32x32" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=32&s=32",
                    "48x48" =>
                      "https://avatar-management--avatars.server-location.prod.public.atl-paas.net/initials/MK-6.png?size=48&s=48"
                  },
                  "displayName" => "Max Krystof",
                  "emailAddress" => "max@example.com",
                  "self" =>
                    "https://your-domain.atlassian.net/rest/api/2/user?accountId=6b10a2844c20165700ede21g",
                  "timeZone" => "Australia/Sydney"
                }
              ]} ==
               Jiraffe.User.get_bulk_all(client,
                 maxResults: 1,
                 accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"]
               )
    end
  end
end
