defmodule Jiraffe.Issue.Field.Metadata.Schema do
  @moduledoc """
  Details of the schema defining a field.
  """

  defstruct configuration: %{},
            custom: "",
            custom_id: 0,
            items: nil,
            system: nil,
            type: ""

  def new(), do: %__MODULE__{}

  def new(body) do
    %__MODULE__{
      configuration: Map.get(body, "configuration", %{}),
      custom: Map.get(body, "custom", ""),
      custom_id: Map.get(body, "customId", 0),
      items: Map.get(body, "items", nil),
      system: Map.get(body, "system", nil),
      type: Map.get(body, "type", "")
    }
  end
end
