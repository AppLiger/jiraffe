defmodule Jiraffe do
  @moduledoc """
  Documentation for `Jiraffe`.
  """
  use Tesla

  @type auth_params() :: %{
          basic:
            %{email: String.t(), token: String.t()}
            | %{username: String.t(), password: String.t()},
          oauth2: %{access_token: String.t()},
          personal_access_token: String.t(),
          token: String.t()
        }

  @doc """
  Reteruns a Tesla client with correct Base URL and Authorization headers
  """
  @spec client(base_url :: String.t(), auth_params :: auth_params()) :: Tesla.Client.t()
  def client(base_url, auth_params) do
    Jiraffe.Client.new(base_url, auth_params)
  end

  @doc """
  Streams pages of results from a Jira API endpoint
  """
  @spec stream_pages(
          get_page :: (Keyword.t() -> {:ok, map()} | {:error, any()}),
          per_page :: non_neg_integer()
        ) :: Enum.t()
  def stream_pages(get_page, per_page) do
    Stream.resource(
      fn -> 0 end,
      fn
        page_number when page_number < 0 ->
          {:halt, page_number}

        page_number ->
          case get_page.(startAt: page_number * per_page, maxResults: per_page) do
            {:ok, %{"isLast" => true} = page} -> {[page], -1}
            {:ok, %{"isLast" => false} = page} -> {[page], page_number + 1}
            _ -> {:halt, page_number}
          end
      end,
      & &1
    )
  end
end
