defmodule Jiraffe.Agile.Issue.Rank do
  @moduledoc false

  alias Jiraffe.{Error, Agile}

  require Logger

  @spec rank_after_issue(
          client :: Jiraffe.Client.t(),
          issue_id :: String.t(),
          issues :: list(String.t()),
          params :: Agile.Issue.rank_params()
        ) :: {:ok, String.t()} | {:error, Error.t()}
  def rank_after_issue(client, issue_id, issues, params \\ []) do
    params =
      %{
        rankAfterIssue: issue_id,
        issues: issues,
        rankCustomFieldId: Keyword.get(params, :rank_custom_field_id)
      }
      |> Map.reject(fn {_, v} -> is_nil(v) end)

    rank(client, params)
  end

  @spec rank_before_issue(
          client :: Jiraffe.Client.t(),
          issue_id :: String.t(),
          issues :: list(String.t()),
          params :: Agile.Issue.rank_params()
        ) :: {:ok, String.t()} | {:error, Error.t()}
  def rank_before_issue(client, issue_id, issues, params \\ []) do
    params =
      %{
        rankBeforeIssue: issue_id,
        issues: issues,
        rankCustomFieldId: Keyword.get(params, :rank_custom_field_id)
      }
      |> Map.reject(fn {_, v} -> is_nil(v) end)

    rank(client, params)
  end

  @spec rank(
          client :: Jiraffe.Client.t(),
          body ::
            %{
              rankAfterIssue: String.t() | nil,
              issues: list(String.t()),
              rankCustomFieldId: non_neg_integer() | nil
            }
            | %{
                rankBeforeIssue: String.t() | nil,
                issues: list(String.t()),
                rankCustomFieldId: non_neg_integer() | nil
              }
        ) :: {:ok, term()} | {:error, Error.t()}
  defp rank(client, body) do
    case Jiraffe.put(
           client,
           "/rest/agile/1.0/issue/rank",
           body
         ) do
      {:ok, %{status: 204}} ->
        {:ok, ""}

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
