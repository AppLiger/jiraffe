defmodule Jiraffe.Issue.BulkCreateResult do
  @moduledoc """
  Bulk create Jira issues result struct.
  """
  defstruct errors: [], issues: %{}

  @type t() :: %__MODULE__{
          errors: [Jiraffe.BulkOperationErrorResult.t()],
          issues: [Jiraffe.Issue.Created.t()]
        }

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.Issue.BulkCreateResult` struct.
  """
  @spec new(map()) :: t()
  def new(body) do
    %__MODULE__{
      errors: Map.get(body, "errors", []) |> Enum.map(&Jiraffe.BulkOperationErrorResult.new/1),
      issues: Map.get(body, "issues", []) |> Enum.map(&Jiraffe.Issue.Created.new/1)
    }
  end
end

defmodule Jiraffe.Issue.BulkCreate do
  @moduledoc false
  alias Jiraffe.Error

  @spec create(
          client :: Jiraffe.Client.t(),
          updates :: [Jiraffe.Issue.UpdateDetails.t()]
        ) :: {:ok, Jiraffe.Issue.BulkCreateResult.t()} | {:error, Error.t()}
  def create(client, body) do
    case Jiraffe.post(
           client,
           "/rest/api/2/issue/bulk",
           %{
             issueUpdates: body |> Enum.map(&Jiraffe.Issue.UpdateDetails.new/1)
           }
         ) do
      {:ok, %{status: 201, body: body}} ->
        {:ok, Jiraffe.Issue.BulkCreateResult.new(body)}

      {:ok, response} ->
        {:error, Error.new(:cannot_create_issues, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
