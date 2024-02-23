defmodule Jiraffe.BulkOperationErrorResult do
  @moduledoc """
  Details about a failed bulk operation.
  """

  @type t() :: %__MODULE__{
          element_errors: Jiraffe.ErrorCollection.t() | nil,
          failed_element_number: integer() | nil,
          status: integer() | nil
        }

  defstruct [
    # ErrorCollection struct
    element_errors: nil,
    # The number of the failed element
    failed_element_number: nil,
    # The status code
    status: nil
  ]

  def new(body) do
    %__MODULE__{
      element_errors: Map.get(body, "elementErrors", nil) |> Jiraffe.ErrorCollection.new(),
      failed_element_number: Map.get(body, "failedElementNumber", nil),
      status: Map.get(body, "status", nil)
    }
  end
end
