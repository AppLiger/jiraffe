defmodule Jiraffe.Agile.Sprint do
  @moduledoc """
  APIs related to sprints
  """

  @type t() :: map()

  alias Jiraffe.{Client, Error}

  @doc """
  Returns the sprint for a given sprint ID.
  The sprint will only be returned if the user can view the board that the sprint was created on,
  or view at least one of the issues in the sprint.
  """
  @spec get(
          client :: Client.t(),
          id :: binary()
        ) :: {:ok, t()} | {:error, Error.t()}
  def get(client, sprint_id) do
    case Jiraffe.get(
           client,
           "/rest/agile/1.0/sprint/#{sprint_id}"
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, response} ->
        {:error, Error.new(:cannot_get_sprint, response)}

      {:error, reason} ->
        {:error, Error.new(:cannot_get_sprint, reason)}
    end
  end
end
