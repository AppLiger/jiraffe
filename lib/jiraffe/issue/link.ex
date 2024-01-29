defmodule Jiraffe.Issue.Link do
  @moduledoc """
  This resource represents links between issues.
  Use it to get, create, and delete links between issues.
  """

  alias __MODULE__
  alias Jiraffe.{Client, Error}

  @type t() :: map()

  defmodule Type do
    @moduledoc """
    The type of link between the issues.
    """

    defstruct id: "",
              self: "",
              name: "",
              inward: "",
              outward: ""

    @doc """
    Converts a map (received from Jira API) to `Jiraffe.Issue.Link.Type` struct.
    """
    def new(body) do
      %__MODULE__{
        id: Map.get(body, "id", ""),
        self: Map.get(body, "self", ""),
        name: Map.get(body, "name", ""),
        inward: Map.get(body, "inward", ""),
        outward: Map.get(body, "outward", "")
      }
    end
  end

  defstruct id: "",
            self: "",
            inward_issue: nil,
            outward_issue: nil,
            type: nil

  @doc """
  Converts a map (received from Jira API) to `Jiraffe.Issue.Link` struct.
  """
  def new(body) do
    inward_issue =
      case Map.fetch(body, "inwardIssue") do
        {:ok, inward_issue} ->
          Jiraffe.Issue.new(inward_issue)

        :error ->
          nil
      end

    outward_issue =
      case Map.fetch(body, "outwardIssue") do
        {:ok, outward_issue} ->
          Jiraffe.Issue.new(outward_issue)

        :error ->
          nil
      end

    type =
      case Map.fetch(body, "type") do
        {:ok, type} ->
          Link.Type.new(type)

        :error ->
          nil
      end

    %__MODULE__{
      id: Map.get(body, "id", ""),
      self: Map.get(body, "self", ""),
      inward_issue: inward_issue,
      outward_issue: outward_issue,
      type: type
    }
  end

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
        {:ok, new(body)}

      {:ok, response} ->
        {:error, Error.new(:cannot_create_issue_link, response)}

      {:error, reason} ->
        {:error, Error.new(:cannot_create_issue_link, reason)}
    end
  end
end
