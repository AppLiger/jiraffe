defmodule Jiraffe.Issue.CreateMetadata.Project do
  @moduledoc """
  Details of the issue creation metadata for a project.
  """

  alias __MODULE__

  @type t() :: %__MODULE__{
          expand: String.t() | nil,
          self: String.t() | nil,
          id: String.t() | nil,
          key: String.t() | nil,
          name: String.t() | nil,
          avatar_urls: Jiraffe.Avatar.Url.t() | nil,
          issue_types: [Project.IssueType.t()]
        }

  defstruct [
    # Expand options that include additional project issue create metadata details in the response
    expand: nil,
    # The URL of the project
    self: nil,
    # The ID of the project
    id: nil,
    # The key of the project
    key: nil,
    # The name of the project
    name: nil,
    # AvatarUrls struct (not defined here)
    avatar_urls: %Jiraffe.Avatar.Url{},
    # List of IssueTypeIssueCreateMetadata structs (not defined here)
    issue_types: []
  ]

  @spec new(map()) :: t()
  def new(body) do
    issue_types =
      Map.get(body, "issuetypes", [])
      |> Enum.map(&Project.IssueType.new/1)

    %__MODULE__{
      expand: body["expand"],
      self: body["self"],
      id: body["id"],
      key: body["key"],
      name: body["name"],
      avatar_urls: Jiraffe.Avatar.Url.new(body["avatarUrls"]),
      issue_types: issue_types
    }
  end
end
