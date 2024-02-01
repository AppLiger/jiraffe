defmodule Jiraffe.Issue.Link do
  @moduledoc """
  This resource represents links between issues.
  Use it to get, create, and delete links between issues.
  """

  alias __MODULE__
  alias Jiraffe.{Error, Issue}

  @type t() :: %__MODULE__{
          id: String.t(),
          self: String.t(),
          inward_issue: Issue.t() | nil,
          outward_issue: Issue.t() | nil,
          type: Link.Type.t() | nil
        }

  defmodule Type do
    @moduledoc """
    The type of link between the issues.
    """

    @type t() :: %__MODULE__{
            id: String.t(),
            self: String.t(),
            name: String.t(),
            inward: String.t(),
            outward: String.t()
          }

    defstruct id: "",
              self: "",
              name: "",
              inward: "",
              outward: ""

    @doc """
    Converts a map (received from Jira API) to `Jiraffe.Issue.Link.Type` struct.
    """
    @spec new(map()) :: t()
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
  @spec new(map()) :: t()
  def new(body) do
    inward_issue =
      case Map.fetch(body, "inwardIssue") do
        {:ok, inward_issue} ->
          Issue.new(inward_issue)

        :error ->
          nil
      end

    outward_issue =
      case Map.fetch(body, "outwardIssue") do
        {:ok, outward_issue} ->
          Issue.new(outward_issue)

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

  @doc false
  @spec create(
          client :: Jiraffe.client(),
          params :: Issue.link_params()
        ) :: {:ok, t()} | {:error, Exception.t()}
  def create(client, params) do
    body =
      %{
        type: %{
          id: Keyword.get(params, :type_id)
        },
        inwardIssue: %{
          id: Keyword.get(params, :inward_issue_id)
        },
        outwardIssue: %{
          id: Keyword.get(params, :outward_issue_id)
        },
        comment: Keyword.get(params, :comment)
      }
      |> Map.reject(fn {_, v} -> is_nil(v) end)

    case Jiraffe.post(
           client,
           "/rest/api/2/issueLink",
           body
         ) do
      {:ok, %{status: 201, body: _body}} ->
        {:ok, %{}}

      {:ok, response} ->
        {:error, Error.new(:cannot_create_issue_link, response)}

      {:error, reason} ->
        {:error, Error.new(:cannot_create_issue_link, reason)}
    end
  end
end
