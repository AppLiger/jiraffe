defmodule Jiraffe.Client do
  @moduledoc """
  HTTP client for Jira
  """

  @type t() :: Tesla.Client.t()

  @doc """
  Hello world.

  ## Examples

      iex> Jiraffe.Client.new("https://example.atlassian.net", aouth2: %{access_token: "a-token"})
      %Tesla.Client{}

  """
  def new(base_url, oauth2: %{access_token: token}) do
    new_bearer(base_url, token)
  end

  def new(base_url, basic: %{email: email, token: token}) do
    new_basic(base_url, Base.encode64("#{email}:#{token}"))
  end

  def new(base_url, basic: %{username: username, password: password}) do
    new_basic(base_url, Base.encode64("#{username}:#{password}"))
  end

  def new(base_url, personal_access_token: token) do
    new_bearer(base_url, token)
  end

  def new(base_url, token) do
    new_bearer(base_url, token)
  end

  defp new_basic(base_url, token) do
    new_client(base_url, "Basic #{token}")
  end

  defp new_bearer(base_url, token) do
    new_client(base_url, "Bearer #{token}")
  end

  defp new_client(base_url, auth_header) do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      # Tesla.Middleware.Logger,
      # Tesla.Middleware.Compression,
      # {Tesla.Middleware.JSON,
      #  decode: fn data ->
      #    case Poison.decode(data) do
      #      {:ok, result} -> {:ok, result}
      #      _ -> data
      #    end
      #  end},
      # {Tesla.Middleware.Retry,
      #  delay: 2_000,
      #  max_retries: 20,
      #  max_delay: 6_000,
      #  should_retry: fn
      #    {:ok, %{status: status}}, _env, %{retries: _retries}
      #    when status in [429] ->
      #      true

      #    {:ok, _reason}, _env, _context ->
      #      false

      #    {:error, _}, _env, _context ->
      #      true
      #  end},
      {Tesla.Middleware.Headers,
       [
         {"authorization", auth_header}
       ]}
    ]

    # adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    Tesla.client(middleware)
  end
end
