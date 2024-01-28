defmodule Jiraffe.ErrorCollection do
  @moduledoc """
  Error messages from an operation.
  """

  defstruct [
    # The list of error messages produced by this operation
    error_messages: [],
    # Map of errors by parameter returned by the operation
    errors: %{},
    # The status code
    status: nil
  ]

  def new(body) do
    %__MODULE__{
      error_messages: Map.get(body, "errorMessages", []),
      errors: Map.get(body, "errors", %{}),
      status: Map.get(body, "status", nil)
    }
  end
end
