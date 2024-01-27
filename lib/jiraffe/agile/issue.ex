defmodule Jiraffe.Agile.Issue do
  @moduledoc """
  APIs related to issues in Jira Software projects
  """

  alias Jiraffe.{Client, Error}

  require Logger

  @type error() :: {:error, Error.t()}

  @doc """
  Moves (ranks) issues before or after a given issue. At most 50 issues may be ranked at once.
  If rankCustomFieldId is not defined, the default rank field will be used.
  """
  @spec rank(
          client :: Client.t(),
          body ::
            %{
              rankAfterIssue: String.t() | nil,
              issues: list(String.t())
            }
            | %{
                rankBeforeIssue: String.t() | nil,
                issues: list(String.t())
              }
        ) :: {:ok, String.t()} | error()
  def rank(client, body) do
    case Jiraffe.put(
           client,
           "/rest/agile/1.0/issue/rank",
           body
         ) do
      {:ok, %{status: 204, body: body}} ->
        Logger.debug("Successfully ranked issues")
        {:ok, body}

      {:ok, %{status: 207, body: %{"entries" => entries}}} ->
        details =
          entries
          |> Enum.flat_map(fn entry -> Map.get(entry, "errors", []) end)
          |> Enum.uniq()
          |> Enum.join(", ")

        Logger.debug("Failed to rank issues: #{details}")

        {:error, Error.new(:cannot_rank_issues, details)}

      {:ok, response} ->
        Logger.debug("Failed to rank issues: #{response.status}")
        {:error, Error.new(:cannot_rank_issues, response)}

      {:error, reason} ->
        Logger.debug("Failed to rank issues: #{inspect(reason)}")
        {:error, Error.new(reason)}
    end
  end
end
