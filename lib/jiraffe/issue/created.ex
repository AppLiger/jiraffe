defmodule Jiraffe.Issue.Created do
  @moduledoc """
  Details about a created issue or subtask.
  """

  defstruct id: "",
            key: "",
            self: "",
            # NestedResponse struct
            transition: nil

  @spec new(map()) :: %__MODULE__{}
  def new(body) do
    transition = Map.get(body, "transition")

    %__MODULE__{
      id: Map.get(body, "id", ""),
      key: Map.get(body, "key", ""),
      self: Map.get(body, "self", ""),
      transition: transition && Jiraffe.NestedResponse.new(transition)
    }
  end
end
