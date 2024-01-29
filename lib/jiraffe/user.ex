defmodule Jiraffe.User do
  @moduledoc """
  This resource represent users. Use it to:
    - get, get a list of, create, and delete users.
    - get, set, and reset a user's default issue table columns.
    - get a list of the groups the user belongs to.
    - get a list of user account IDs for a list of usernames or user keys.
  """

  @type t() :: map()

  defstruct [
    # The URL of the user
    self: "",
    # The account ID of the user
    account_id: "",
    # The email address of the user (nullable)
    email_address: nil,
    avatar_urls: %Jiraffe.Avatar.Url{},
    # The display name of the user
    display_name: "",
    # Whether the user is active
    active: false,
    # The time zone specified in the user's profile (nullable)
    time_zone: nil,
    # The type of account represented by this user
    account_type: ""
  ]

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.User` struct.
  """
  def new(data) do
    avatar_urls =
      Map.get(data, "avatarUrls", %{})
      |> Jiraffe.Avatar.Url.new()

    %__MODULE__{
      account_id: Map.get(data, "accountId", ""),
      account_type: Map.get(data, "accountType", ""),
      active: Map.get(data, "active", false),
      avatar_urls: avatar_urls,
      display_name: Map.get(data, "displayName", ""),
      email_address: Map.get(data, "emailAddress", nil),
      self: Map.get(data, "self", ""),
      time_zone: Map.get(data, "timeZone", nil)
    }
  end
end
