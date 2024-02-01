defmodule Jiraffe.Agile.Issue do
  @moduledoc """
  APIs related to issues in Jira Software projects
  """

  alias __MODULE__
  alias Jiraffe.Error

  @type rank_params :: [
          rank_custom_field_id: non_neg_integer() | nil
        ]

  @doc """
  Moves (ranks) issues after a given issue. At most 50 issues may be ranked at once.
  If `rank_custom_field_id` is not defined, the default rank field will be used.
  """
  @spec rank_after_issue(
          client :: Jiraffe.client(),
          issue_id :: String.t(),
          issue_ids :: list(String.t()),
          params :: rank_params()
        ) :: {:ok, String.t()} | {:error, Error.t()}
  defdelegate rank_after_issue(client, issue_id, issues, params \\ []), to: Issue.Rank

  @doc """
  Moves (ranks) issues before a given issue. At most 50 issues may be ranked at once.
  If `rank_custom_field_id` is not defined, the default rank field will be used.
  """
  @spec rank_before_issue(
          client :: Jiraffe.client(),
          issue_id :: String.t(),
          issue_ids :: list(String.t()),
          params :: rank_params()
        ) :: {:ok, String.t()} | {:error, Error.t()}
  defdelegate rank_before_issue(client, issue_id, issues, params \\ []), to: Issue.Rank
end
