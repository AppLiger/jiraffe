defmodule Jiraffe.Issue.CreateMetadata.Project.IssueType do
  @moduledoc """
  Details of the issue creation metadata for an issue type.
  """

  alias Jiraffe.Issue.Field.Metadata

  defstruct [
    # The URL of these issue type details
    self: nil,
    # The ID of the issue type
    id: nil,
    # The description of the issue type
    description: nil,
    # The URL of the issue type's avatar
    icon_url: nil,
    # The name of the issue type
    name: nil,
    # Whether this issue type is used to create subtasks
    subtask?: false,
    # The ID of the issue type's avatar
    avatar_id: 0,
    # Unique ID for next-gen projects
    entity_id: nil,
    # Hierarchy level of the issue type
    hierarchy_level: 0,
    # Scope struct (not defined here)
    scope: nil,
    # Expand options that include additional issue type metadata details in the response
    expand: nil,
    # Map of the fields available when creating an issue for the issue type
    fields: %{}
  ]

  def new(body) do
    fields =
      Map.get(body, "fields", %{})
      |> Enum.map(fn {key, value} -> {key, Metadata.new(value)} end)
      |> Map.new()

    %__MODULE__{
      self: body["self"],
      id: body["id"],
      description: body["description"],
      icon_url: body["iconUrl"],
      name: body["name"],
      subtask?: body["subtask"] == true,
      avatar_id: body["avatarId"],
      entity_id: body["entityId"],
      hierarchy_level: Map.get(body, "hierarchyLevel", 0),
      scope: body["scope"],
      expand: body["expand"],
      fields: fields
    }
  end
end
