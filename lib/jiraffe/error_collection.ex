defmodule Jiraffe.ErrorCollection do
  @moduledoc """
  Error messages from an operation.

  - `error_messages` - The list of error messages produced by this operation
  - `errors` - Map of errors by parameter returned by the operation
  - `status` - The status code
  """

  @type t() :: %__MODULE__{
          error_messages: [String.t()],
          errors: map(),
          status: integer() | nil
        }

  defstruct error_messages: [],
            errors: %{},
            status: nil

  def new(body) do
    %__MODULE__{
      error_messages: Map.get(body, "errorMessages", []),
      errors: Map.get(body, "errors", %{}),
      status: Map.get(body, "status", nil)
    }
  end
end
