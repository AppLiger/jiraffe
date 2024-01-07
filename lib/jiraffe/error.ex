defmodule Jiraffe.Error do
  @moduledoc """
  Error struct
  """

  @type t() :: %__MODULE__{
          reason: atom(),
          details: map()
        }

  defexception [:reason, :details]

  @spec new(details :: map() | String.t()) :: t()
  def new(details) when not is_atom(details) do
    %__MODULE__{
      reason: :general,
      details: details
    }
  end

  @spec new(reason :: atom(), details :: map() | String.t()) :: t()
  def new(reason, details \\ %{}) do
    %__MODULE__{
      reason: reason,
      details: details
    }
  end

  @impl Exception
  def message(_error), do: "Jira API error"
end
