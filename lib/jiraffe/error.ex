defmodule Jiraffe.Error do
  @moduledoc """
  Error struct
  """

  @type t() :: %__MODULE__{
          reason: atom(),
          details: map()
        }

  defexception [:reason, :details]

  def new(reason, details \\ %{}) do
    %__MODULE__{
      reason: reason,
      details: details
    }
  end

  @impl Exception
  def message(_error), do: "Jira API error"
end
