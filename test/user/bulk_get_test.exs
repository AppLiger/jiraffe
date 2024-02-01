defmodule Jiraffe.User.BulkGetTest do
  @moduledoc false
  use ExUnit.Case

  import Tesla.Mock
  import JiraffeTest.Support

  alias Jiraffe.ResultsPage

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
          maxResults: 1,
          startAt: 0
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
          maxResults: 1,
          startAt: 1
        ]
      } ->
        json(
          jira_response_body("api/2/user/bulk.2"),
          status: 200
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [
          maxResults: 1,
          startAt: 1,
          accountId: ["5b10a2844c20165700ede21g", "6b10a2844c20165700ede21g"]
        ]
      } ->
        json(
          jira_response_body("api/2/user/bulk.2"),
          status: 200
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [accountId: ["fail"]]
      } ->
        json(
          %{},
          status: 400
        )

      %{
        method: :get,
        url: "https://your-domain.atlassian.net/rest/api/2/user/bulk",
        query: [accountId: ["raise"]]
      } ->
        %Tesla.Error{reason: :something_went_wrong}

      unexpected ->
        raise "Unexpected request: #{inspect(unexpected)}"
    end)

    client = Jiraffe.Client.new("https://your-domain.atlassian.net", "a-token")

    mia = %Jiraffe.User{
      account_id: "5b10a2844c20165700ede21g",
      account_type: "atlassian",
      active?: true,
      avatar_urls: %Jiraffe.Avatar.Url{
        tiny: "https://avatar.net/initials/MK-5.png?size=16&s=16",
        small: "https://avatar.net/initials/MK-5.png?size=24&s=24",
        medium: "https://avatar.net/initials/MK-5.png?size=32&s=32",
        large: "https://avatar.net/initials/MK-5.png?size=48&s=48"
      },
      display_name: "Mia Krystof",
      email_address: "mia@example.com",
      self:
        "https://your-domain.atlassian.net/rest/api/2/user?accountId=5b10a2844c20165700ede21g",
      time_zone: "Australia/Sydney"
    }

    max = %Jiraffe.User{
      account_id: "6b10a2844c20165700ede21g",
      account_type: "atlassian",
      active?: true,
      avatar_urls: %Jiraffe.Avatar.Url{
        tiny: "https://avatar.net/initials/MK-6.png?size=16&s=16",
        small: "https://avatar.net/initials/MK-6.png?size=24&s=24",
        medium: "https://avatar.net/initials/MK-6.png?size=32&s=32",
        large: "https://avatar.net/initials/MK-6.png?size=48&s=48"
      },
      display_name: "Max Krystof",
      email_address: "max@example.com",
      self:
        "https://your-domain.atlassian.net/rest/api/2/user?accountId=6b10a2844c20165700ede21g",
      time_zone: "Australia/Sydney"
    }

    {:ok, client: client, mia: mia, max: max}
  end

  describe "bulk_get/2" do
    test "return first page of users matching the provided criteria",
         %{client: client, mia: mia} do
      assert {:ok,
              %ResultsPage{
                is_last: false,
                max_results: 1,
                start_at: 0,
                total: 2,
                values: [mia]
              }} ==
               Jiraffe.User.bulk_get(client,
                 account_ids: [
                   "5b10a2844c20165700ede21g",
                   "6b10a2844c20165700ede21g"
                 ]
               )
    end

    test "returns second page of users matching the provided criteria", %{
      client: client,
      max: max
    } do
      assert {:ok,
              %ResultsPage{
                is_last: true,
                max_results: 1,
                start_at: 1,
                total: 2,
                values: [max]
              }} ==
               Jiraffe.User.bulk_get(client,
                 start_at: 1,
                 max_results: 1,
                 account_ids: [
                   "5b10a2844c20165700ede21g",
                   "6b10a2844c20165700ede21g"
                 ]
               )
    end

    test "returns error when Jira returns error", %{client: client} do
      assert {:error,
              %Jiraffe.Error{
                reason: :cannot_get_users_list,
                details: %{}
              }} ==
               Jiraffe.User.bulk_get(client,
                 account_ids: ["fail"]
               )
    end

    test "returns error when gets error", %{client: client} do
      assert {:error,
              %Jiraffe.Error{
                details: %Tesla.Error{
                  env: nil,
                  stack: [],
                  reason: :something_went_wrong
                },
                reason: :general
              }} ==
               Jiraffe.User.bulk_get(client,
                 account_ids: ["raise"]
               )
    end
  end

  describe "bulk_get_stream/2" do
    test "returns stream of pages of users matching the provided criteria",
         %{
           client: client,
           mia: mia,
           max: max
         } do
      assert [
               %ResultsPage{
                 is_last: false,
                 max_results: 1,
                 start_at: 0,
                 total: 2,
                 values: [mia]
               },
               %ResultsPage{
                 is_last: true,
                 max_results: 1,
                 start_at: 1,
                 total: 2,
                 values: [max]
               }
             ] ==
               Jiraffe.User.bulk_get_stream(client,
                 max_results: 1,
                 account_ids: [
                   "5b10a2844c20165700ede21g",
                   "6b10a2844c20165700ede21g"
                 ]
               )
               |> Enum.to_list()
    end
  end

  describe "bulk_get_all/2" do
    test "returns all users matching the provided criteria",
         %{client: client, mia: mia, max: max} do
      assert {:ok, [mia, max]} ==
               Jiraffe.User.bulk_get_all(client,
                 max_results: 1,
                 account_ids: [
                   "5b10a2844c20165700ede21g",
                   "6b10a2844c20165700ede21g"
                 ]
               )
    end
  end
end
