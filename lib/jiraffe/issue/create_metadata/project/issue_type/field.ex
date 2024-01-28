defmodule Jiraffe.Issue.CreateMetadata.Project.IssueType.Field do
  @moduledoc """
  Details of the fields available when creating an issue for the issue type.
  """
  alias __MODULE__

  defstruct allowed_values: [],
            auto_complete_url: nil,
            configuration: %{},
            default_value: nil,
            has_default_value?: false,
            key: "",
            name: "",
            operations: [],
            required?: false,
            schema: Field.Schema.new()

  def new(body) do
    %__MODULE__{
      allowed_values: Map.get(body, "allowedValues", []),
      auto_complete_url: Map.get(body, "autoCompleteUrl", nil),
      configuration: Map.get(body, "configuration", %{}),
      default_value: Map.get(body, "defaultValue", nil),
      has_default_value?: Map.get(body, "hasDefaultValue", false),
      key: Map.get(body, "key", ""),
      name: Map.get(body, "name", ""),
      operations: Map.get(body, "operations", []),
      required?: Map.get(body, "required", false),
      schema: Field.Schema.new(body["schema"])
    }
  end
end
