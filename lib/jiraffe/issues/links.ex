defmodule Jiraffe.Issues.Links do
  @moduledoc """
  This resource represents links between issues.
  Use it to get, create, and delete links between issues.
  """

  alias Jiraffe.{Client, Error}

  @type t() :: map()

  @doc """
  Creates a link between two issues.
  Use this operation to indicate a relationship between two issues
  and optionally add a comment to the from (outward) issue.
  """
  @spec create(
          client :: Client.t(),
          body :: map()
        ) :: {:ok, String.t()} | {:error, Exception.t()}
  def create(client, body) do
    case Jiraffe.post(
           client,
           "/rest/api/2/issueLink",
           body
         ) do
      {:ok, %{status: 201, body: body}} ->
        {:ok, body}

      {:ok, response} ->
        {:error, Error.new(:cannot_create_issue_link, response)}

      {:error, reason} ->
        {:error, Error.new(:cannot_create_issue_link, reason)}
    end
  end
end
