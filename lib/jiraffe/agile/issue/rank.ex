defmodule Jiraffe.Agile.Issue.Rank do
  @moduledoc """
  Agile Issue ranking
  """

  alias Jiraffe.{Client, Error}

  require Logger

  @doc """
  Moves (ranks) issues after a given issue. At most 50 issues may be ranked at once.
  If `rank_custom_field_id` is not defined, the default rank field will be used.
  """
  @spec rank_after_issue(
          client :: Client.t(),
          issue_id :: String.t(),
          issues :: list(String.t()),
          opts :: Keyword.t()
        ) :: {:ok, String.t()} | {:error, Error.t()}
  def rank_after_issue(client, issue_id, issues, opts \\ []) do
    params =
      %{
        rankAfterIssue: issue_id,
        issues: issues,
        rankCustomFieldId: Keyword.get(opts, :rank_custom_field_id)
      }
      |> Map.reject(fn {_, v} -> is_nil(v) end)

    rank(client, params)
  end

  @doc """
  Moves (ranks) issues before a given issue. At most 50 issues may be ranked at once.
  If `rank_custom_field_id` is not defined, the default rank field will be used.
  """
  @spec rank_before_issue(
          client :: Client.t(),
          issue_id :: String.t(),
          issues :: list(String.t()),
          opts :: Keyword.t()
        ) :: {:ok, String.t()} | {:error, Error.t()}
  def rank_before_issue(client, issue_id, issues, opts \\ []) do
    params =
      %{
        rankBeforeIssue: issue_id,
        issues: issues,
        rankCustomFieldId: Keyword.get(opts, :rank_custom_field_id)
      }
      |> Map.reject(fn {_, v} -> is_nil(v) end)

    rank(client, params)
  end

  @spec rank(
          client :: Client.t(),
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
