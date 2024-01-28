defmodule Jiraffe.Issue.EditMetadata do
  @moduledoc """
  This resource returns details of the edit screen fields for an issue that are visible to and editable by the user.
  """

  alias Jiraffe.{Client, Error}
  alias Jiraffe.Issue.Field.Metadata

  defstruct fields: %{}

  @type t() :: %__MODULE__{}

  @doc """
  Converts a map (received from Jira API) to `Jira.Issue.EditMetadata` struct.
  """
  def new(body) do
    fields =
      Map.get(body, "fields", %{})
      |> Enum.map(fn {key, value} -> {key, Metadata.new(value)} end)
      |> Map.new()

    %__MODULE__{
      fields: fields
    }
  end

  @doc """
  Returns the edit screen fields for an issue that are visible to and editable by the user.
  """
  @spec get(client :: Client.t(), params :: Keyword.t()) ::
          {:ok, t()} | {:error, Error.t()}
  def get(client, issue_id_or_key, params \\ []) do
    case Jiraffe.get(
           client,
           "/rest/api/2/issue/#{issue_id_or_key}/editmeta",
           query: params
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, new(body)}

      {:ok, response} ->
        {:error, Error.new(:cannot_get_edit_issue_metadata, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
