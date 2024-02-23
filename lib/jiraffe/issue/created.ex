defmodule Jiraffe.Issue.Created do
  @moduledoc """
  Details about a created issue or subtask.
  """

  @type t() :: %__MODULE__{
          id: String.t(),
          key: String.t(),
          self: String.t(),
          transition: Jiraffe.NestedResponse.t() | nil
        }

  defstruct id: "",
            key: "",
            self: "",
            transition: nil

  @spec new(map()) :: t()
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
