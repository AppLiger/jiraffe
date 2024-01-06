defmodule Jiraffe.Issues do
  @moduledoc """
  Jira Issue
  """
  alias Jiraffe.{Client, Error}

  @type t() :: map()
  @type error() :: {:error, Error.t()}

  @doc """
  Get an issue by ID or key

  [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v2/api-group-issues/#api-rest-api-2-issue-issueidorkey-get)
  """
  @spec get(
          client :: Client.t(),
          id_or_key :: binary(),
          params :: Keyword.t()
        ) :: {:ok, t()} | error()
  def get(client, id_or_key, params \\ []) do
    case Jiraffe.get(client, "/rest/api/2/issue/" <> id_or_key, query: params) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, result} ->
        {:error, Error.new(:unexpected_status, result)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
