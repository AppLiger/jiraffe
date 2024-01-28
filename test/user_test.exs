defmodule Jiraffe.UserTest do
  @moduledoc false
  use ExUnit.Case

  describe "new/1" do
    test "converts" do
      assert %Jiraffe.User{
               account_id: "6b10a2844c20165700ede21g",
               account_type: "atlassian",
               active: true,
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
             } ==
               Jiraffe.User.new(%{
                 "accountId" => "6b10a2844c20165700ede21g",
                 "accountType" => "atlassian",
                 "active" => true,
                 "avatarUrls" => %{
                   "16x16" => "https://avatar.net/initials/MK-6.png?size=16&s=16",
                   "24x24" => "https://avatar.net/initials/MK-6.png?size=24&s=24",
                   "32x32" => "https://avatar.net/initials/MK-6.png?size=32&s=32",
                   "48x48" => "https://avatar.net/initials/MK-6.png?size=48&s=48"
                 },
                 "displayName" => "Max Krystof",
                 "emailAddress" => "max@example.com",
                 "self" =>
                   "https://your-domain.atlassian.net/rest/api/2/user?accountId=6b10a2844c20165700ede21g",
                 "timeZone" => "Australia/Sydney"
               })
    end
  end
end
