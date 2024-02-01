defmodule Jiraffe.Issue.UpdateDetails do
  @moduledoc """
  Issue update body

  - `transition` - `IssueTransition` struct
  - `fields` - Map of issue screen fields to update
  - `udpate` - Map containing field names and operations
  - `history_metadata` - HistoryMetadata struct
  - `properties` - List of EntityProperty structs
  """

  @type t() :: %__MODULE__{
          transition: map() | nil,
          fields: map() | nil,
          update: map() | nil,
          history_metadata: map() | nil,
          properties: list(term()) | nil
        }

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(value, opts) do
      for {key, value} <- Map.from_struct(value),
          value,
          into: %{} do
        {key, value}
      end
      |> Jason.Encode.map(opts)
    end
  end

  defstruct transition: nil,
            fields: nil,
            update: nil,
            history_metadata: nil,
            properties: nil

  def new(body) do
    struct(__MODULE__, body)
  end
end
