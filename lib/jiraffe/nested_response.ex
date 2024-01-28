defmodule Jiraffe.NestedResponse do
  @moduledoc """
  Nested response.
  """

  defstruct status: nil,
            error_collection: nil

  @spec new(map()) :: %__MODULE__{}
  def new(body) do
    %__MODULE__{
      status: Map.get(body, "status", nil),
      error_collection: Map.get(body, "errorCollection", %{}) |> Jiraffe.ErrorCollection.new()
    }
  end
end
