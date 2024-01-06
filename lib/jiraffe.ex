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
end
