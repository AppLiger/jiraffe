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

  @type client() :: Tesla.Client.t()

  @doc """
  Reteruns a Tesla client with correct Base URL and Authorization headers

    Jiraffe.Client.new("https://example.atlassian.net", aouth2: %{access_token: "a-token"})
    %Tesla.Client{}
  """
  @spec client(base_url :: String.t(), auth_params :: auth_params()) :: client()
  def client(base_url, auth_params) do
    Jiraffe.Client.new(base_url, auth_params)
  end
end
