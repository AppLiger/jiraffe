defmodule Jiraffe.Agile.Sprint do
  @moduledoc """
  APIs related to sprints
  """

  @type t() :: map()

  alias Jiraffe.{Client, Error}

  defstruct [
    # The ID of the sprint
    id: 0,
    # The URL of the sprint (nullable)
    self: nil,
    # The state of the sprint
    state: "",
    # The name of the sprint
    name: "",
    # The start date of the sprint (nullable)
    start_date: nil,
    # The end date of the sprint (nullable)
    end_date: nil,
    # The complete date of the sprint (nullable)
    complete_date: nil,
    # The created date of the sprint (nullable)
    created_date: nil,
    # The ID of the origin board (nullable)
    origin_board_id: 0,
    # The goal of the sprint
    goal: ""
  ]

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.Agile.Sprint` struct.
  """
  def new(body) do
    %__MODULE__{
      id: Map.get(body, "id", 0),
      self: Map.get(body, "self", nil),
      state: Map.get(body, "state", ""),
      name: Map.get(body, "name", ""),
      start_date: Map.get(body, "startDate", nil),
      end_date: Map.get(body, "endDate", nil),
      complete_date: Map.get(body, "completeDate", nil),
      created_date: Map.get(body, "createdDate", nil),
      origin_board_id: Map.get(body, "originBoardId", 0),
      goal: Map.get(body, "goal", "")
    }
  end

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
        {:ok, new(body)}

      {:ok, response} ->
        {:error, Error.new(:cannot_get_sprint, response)}

      {:error, reason} ->
        {:error, Error.new(:cannot_get_sprint, reason)}
    end
  end
end
