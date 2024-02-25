defmodule Jiraffe.User do
  @moduledoc """
  This resource represent users. Use it to:
    - get, get a list of, create, and delete users.
    - get, set, and reset a user's default issue table columns.
    - get a list of the groups the user belongs to.
    - get a list of user account IDs for a list of usernames or user keys.
  """

  alias __MODULE__
  alias Jiraffe.{Avatar, Error, ResultsPage}

  @type account_id() :: String.t()

  @type t() :: %__MODULE__{
          self: String.t(),
          account_id: account_id(),
          email_address: String.t() | nil,
          avatar_urls: Avatar.Url.t(),
          display_name: String.t(),
          active?: boolean(),
          time_zone: String.t() | nil,
          account_type: String.t()
        }

  defstruct self: "",
            account_id: "",
            email_address: nil,
            avatar_urls: %Avatar.Url{},
            display_name: "",
            active?: false,
            time_zone: nil,
            account_type: ""

  @type bulk_get_params() :: [
          start_at: non_neg_integer(),
          max_results: non_neg_integer(),
          account_ids: [account_id()]
        ]

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.User` struct.

  - `self` - The URL of the user
  - `account_id` - The account ID of the user
  - `email_address` - The email address of the user
  - `avatar_urls` - The avatar URLs of the user (see `Jiraffe.Avatar.Url`)
  - `display_name` - The display name of the user
  - `active?` - Whether the user is active
  - `time_zone` - The time zone specified in the user's profile
  - `account_type` - The type of account represented by this user
  """
  def new(data) do
    avatar_urls =
      Map.get(data, "avatarUrls", %{})
      |> Avatar.Url.new()

    %__MODULE__{
      account_id: Map.get(data, "accountId", ""),
      account_type: Map.get(data, "accountType", ""),
      active?: Map.get(data, "active", false),
      avatar_urls: avatar_urls,
      display_name: Map.get(data, "displayName", ""),
      email_address: Map.get(data, "emailAddress", nil),
      self: Map.get(data, "self", ""),
      time_zone: Map.get(data, "timeZone", nil)
    }
  end

  @doc """
  (**EXPERIMENTAL**) Returns a page of users matching the provided criteria.

  [Rerefence](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-users/#api-rest-api-2-user-bulk-get)
  """

  @spec bulk_get(
          Jiraffe.Client.t(),
          params :: bulk_get_params()
        ) ::
          {:ok, ResultsPage} | {:error, Error.t()}
  defdelegate bulk_get(client, params), to: User.BulkGet, as: :page

  @doc """
  (**EXPERIMENTAL**) Returns a stream of pages (see `Jiraffe.User.bulk_get/2`) of users matching the provided criteria.
  """

  @spec bulk_get_stream(
          Jiraffe.Client.t(),
          params :: bulk_get_params()
        ) ::
          Enum.t() | {:error, Error.t()}
  defdelegate bulk_get_stream(client, params), to: User.BulkGet, as: :stream

  @doc """
  (**EXPERIMENTAL**) Returns all users matching the provided criteria (see `Jiraffe.User.bulk_get/2`)
  """

  @spec bulk_get_all(
          Jiraffe.Client.t(),
          params :: bulk_get_params()
        ) ::
          {:ok, [t()]} | {:error, Error.t()}
  defdelegate bulk_get_all(client, params), to: User.BulkGet, as: :all
end
