defmodule Jiraffe.Issue.EditMetadata do
  @moduledoc """
  This resource returns details of the edit screen fields for an issue that are visible to and editable by the user.
  """

  alias Jiraffe.Error
  alias Jiraffe.Issue.Field.Metadata

  defstruct fields: %{}

  @type t() :: %__MODULE__{
          fields: map()
        }

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.Issue.EditMetadata` struct.
  """
  @spec new(map()) :: t()
  def new(body) do
    fields =
      Map.get(body, "fields", %{})
      |> Enum.map(fn {key, value} -> {key, Metadata.new(value)} end)
      |> Map.new()

    %__MODULE__{
      fields: fields
    }
  end

  @doc false
  @spec get(
          client :: Jiraffe.Client.t(),
          params :: [
            override_screen_security: boolean(),
            override_editable_flag: boolean()
          ]
        ) ::
          {:ok, t()} | {:error, Error.t()}
  def get(client, issue_id_or_key, params \\ []) do
    params =
      [
        overrideScreenSecurity: Keyword.get(params, :override_screen_security),
        overrideEditableFlag: Keyword.get(params, :override_editable_flag)
      ]
      |> Keyword.reject(fn {_, v} -> is_nil(v) end)

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
