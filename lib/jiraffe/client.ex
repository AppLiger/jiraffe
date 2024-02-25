defmodule Jiraffe.Client do
  @moduledoc false

  @type t() :: Tesla.Client.t()

  def new(base_url, oauth2: %{access_token: token}) do
    new_bearer(base_url, token)
  end

  def new(base_url, basic: %{email: email, token: token}) do
    new_basic(base_url, email, token)
  end

  def new(base_url, basic: %{username: username, password: password}) do
    new_basic(base_url, username, password)
  end

  def new(base_url, personal_access_token: token) do
    new_bearer(base_url, token)
  end

  def new(base_url, token) do
    new_bearer(base_url, token)
  end

  defp new_basic(base_url, username, password) do
    new_client(base_url, {Tesla.Middleware.BasicAuth, username: username, password: password})
  end

  defp new_bearer(base_url, token) do
    new_client(base_url, {Tesla.Middleware.BearerAuth, token: token})
  end

  defp new_client(base_url, auth_middleware) do
    [auth_middleware]
    |> setup_json_middleware()
    |> setup_base_url_middleware(base_url)
    |> setup_debug_middleware()
    |> setup_keep_request_middleware()
    |> setup_retry_middleware()
    |> Tesla.client(adapter())
  end

  defp setup_json_middleware(middleware) do
    middleware ++ [Tesla.Middleware.JSON]
  end

  defp setup_base_url_middleware(middleware, base_url) do
    middleware ++ [{Tesla.Middleware.BaseUrl, base_url}]
  end

  defp setup_debug_middleware(middleware) do
    case Application.get_env(:jiraffe, :debug, false) do
      true -> middleware ++ [Tesla.Middleware.Logger]
      _ -> middleware
    end
  end

  defp setup_keep_request_middleware(middleware) do
    case Application.get_env(:jiraffe, :keep_request, false) do
      true -> middleware ++ [Tesla.Middleware.KeepRequest]
      _ -> middleware
    end
  end

  defp setup_retry_middleware(middleware) do
    case Application.get_env(:jiraffe, :retry, false) do
      true ->
        middleware ++
          [
            {Tesla.Middleware.Retry,
             delay: 1_000,
             max_retries: 3,
             should_retry: fn
               {:ok, %{status: status}}, _env, _context
               when status in [429] ->
                 true

               _result, _env, _context ->
                 false
             end}
          ]

      options when is_list(options) ->
        middleware ++ [{Tesla.Middleware.Retry, options}]

      _ ->
        middleware
    end
  end

  defp adapter do
    case Application.get_env(:jiraffe, :adapter) do
      nil -> {Tesla.Adapter.Hackney, recv_timeout: timeout()}
      adapter when is_tuple(adapter) -> adapter
      adapter -> {adapter, recv_timeout: timeout()}
    end
  end

  defp timeout do
    case Application.get_env(:jiraffe, :timeout) do
      timeout when is_number(timeout) -> timeout
      _ -> 5_000
    end
  end
end
