defmodule JiraffeTest do
  @moduledoc false
  use ExUnit.Case
  doctest Jiraffe

  import Tesla.Mock

  describe "client/2 with a valid Base URL and a Token" do
    test "returns a Tesla client with correct Base URL and Bearer Authorization" do
      client = Jiraffe.client("https://example.atlassian.net", "a-token")

      assert get_bearer_token(client) == "a-token"
      assert get_base_url(client) == "https://example.atlassian.net"
    end
  end

  describe "client/2 with a valid Base URL and a Personal Access Token" do
    test "returns a Tesla client with correct Base URL and Bearer Authorization" do
      client = Jiraffe.client("https://example.atlassian.net", personal_access_token: "a-token")

      assert get_bearer_token(client) == "a-token"
      assert get_base_url(client) == "https://example.atlassian.net"
    end
  end

  describe "client/2 with a valid Base URL and a OAuth2 Access Token" do
    test "returns a Tesla client with correct Base URL and Bearer Authorization" do
      client = Jiraffe.client("https://example.atlassian.net", oauth2: %{access_token: "a-token"})

      assert get_bearer_token(client) == "a-token"
      assert get_base_url(client) == "https://example.atlassian.net"
    end
  end

  describe "client/2 with a valid Base URL, Email and Token" do
    test "returns a Tesla client with correct Base URL and Basic Authorization" do
      client =
        Jiraffe.client("https://example.atlassian.net",
          basic: %{email: "user@example.net", token: "a-token"}
        )

      assert get_basic_auth_username_and_password(client) ==
               {"user@example.net", "a-token"}

      assert get_base_url(client) == "https://example.atlassian.net"
    end
  end

  describe "client/2 with a valid Base URL, Username and Password" do
    test "returns a Tesla client with correct Base URL and Basic Authorization" do
      client =
        Jiraffe.client("https://example.atlassian.net",
          basic: %{username: "user@example.net", password: "a-token"}
        )

      assert get_basic_auth_username_and_password(client) ==
               {"user@example.net", "a-token"}

      assert get_base_url(client) == "https://example.atlassian.net"
    end
  end

  describe "client/2 with :debug configuration" do
    setup do
      on_exit(fn ->
        Application.put_env(:jiraffe, :debug, false)
      end)

      :ok
    end

    test "has no Logger middleware by default" do
      client =
        Jiraffe.client(
          "https://example.atlassian.net",
          "a-token"
        )

      refute has_middleware?(client, Tesla.Middleware.Logger)
    end

    test "has Logger middleware when it is enabled" do
      Application.put_env(:jiraffe, :debug, true)

      client =
        Jiraffe.client(
          "https://example.atlassian.net",
          "a-token"
        )

      assert has_middleware?(client, Tesla.Middleware.Logger)
    end
  end

  describe "client/2 with :keep_request configuration" do
    setup do
      on_exit(fn ->
        Application.put_env(:jiraffe, :keep_request, false)
      end)

      :ok
    end

    test "has no KeepRequest middleware by default" do
      client =
        Jiraffe.client(
          "https://example.atlassian.net",
          "a-token"
        )

      refute has_middleware?(client, Tesla.Middleware.KeepRequest)
    end

    test "has KeepRequest middleware when it is enabled" do
      Application.put_env(:jiraffe, :keep_request, true)

      client =
        Jiraffe.client(
          "https://example.atlassian.net",
          "a-token"
        )

      assert has_middleware?(client, Tesla.Middleware.KeepRequest)
    end
  end

  describe "client/2 with :retry configuration" do
    setup do
      on_exit(fn ->
        Application.put_env(:jiraffe, :retry, false)
      end)

      :ok
    end

    test "has no Retry middleware by default" do
      client =
        Jiraffe.client(
          "https://example.atlassian.net",
          "a-token"
        )

      refute has_middleware?(client, Tesla.Middleware.Retry)
    end

    test "has Retry middleware when it is enabled" do
      Application.put_env(:jiraffe, :retry, true)

      client =
        Jiraffe.client(
          "https://example.atlassian.net",
          "a-token"
        )

      assert has_middleware?(client, Jiraffe.Middleware.Retry)
    end

    test "has Retry middleware with correct options when it is configured" do
      expected_options = [max_retries: 10]

      Application.put_env(:jiraffe, :retry, expected_options)

      client =
        Jiraffe.client(
          "https://example.atlassian.net",
          "a-token"
        )

      {_, _, [options]} = find_middleware(client, Jiraffe.Middleware.Retry)

      assert expected_options == options
    end
  end

  describe "HTTP requests" do
    setup do
      client = Jiraffe.client("https://example.atlassian.net", "a-token")

      mock(fn
        %{method: :get, url: "https://example.atlassian.net/test"} ->
          json(%{ok: true}, status: 200)

        %{method: :post, url: "https://example.atlassian.net/test"} ->
          json(%{ok: true}, status: 201)

        %{method: :put, url: "https://example.atlassian.net/test"} ->
          json(%{ok: true}, status: 204)

        %{method: :delete, url: "https://example.atlassian.net/test"} ->
          json(%{ok: true}, status: 200)
      end)

      {:ok, client: client}
    end

    test "can make GET requests", %{client: client} do
      assert {:ok, %{status: 200, body: %{"ok" => true}}} = Jiraffe.get(client, "/test")
    end

    test "can make POST requests", %{client: client} do
      assert {:ok, %{status: 201, body: %{"ok" => true}}} =
               Jiraffe.post(client, "/test", %{foo: "bar"})
    end

    test "can make PUT requests", %{client: client} do
      assert {:ok, %{status: 204, body: %{"ok" => true}}} =
               Jiraffe.put(client, "/test", %{foo: "bar"})
    end

    test "can make DELETE requests", %{client: client} do
      assert {:ok, %{status: 200, body: %{"ok" => true}}} = Jiraffe.delete(client, "/test")
    end
  end

  @tag :slow
  describe "default retryability behaviour" do
    setup do
      Application.put_env(:jiraffe, :retry, true)

      {:ok, requests_count_pid} = Agent.start_link(fn -> 0 end)

      fn ->
        Application.put_env(:jiraffe, :retry, false)
      end

      mock(fn
        %{method: :get, url: "https://example.atlassian.net/test"} ->
          Agent.cast(requests_count_pid, Kernel, :+, [1])
          json("Too many requests!!!", status: 429)
      end)

      client = Jiraffe.client("https://example.atlassian.net", "a-token")

      get_requests_count = fn -> Agent.get(requests_count_pid, fn state -> state end) end

      {:ok, client: client, get_requests_count: get_requests_count}
    end

    test "retries 3 times on 429", %{client: client, get_requests_count: get_requests_count} do
      Jiraffe.get(client, "/test")

      assert get_requests_count.() == 4
    end
  end

  defp get_base_url(client) do
    case client.pre
         |> Enum.find(fn
           {Tesla.Middleware.BaseUrl, :call, [_base_url]} -> true
           _ -> false
         end) do
      {_, _, [base_url]} -> base_url
      _ -> nil
    end
  end

  defp get_basic_auth_username_and_password(client) do
    case client.pre
         |> Enum.find(fn
           {Tesla.Middleware.BasicAuth, :call, [[username: _usersname, password: _password]]} ->
             true

           _ ->
             false
         end) do
      {_, _, [[username: username, password: password]]} ->
        {username, password}

      _ ->
        nil
    end
  end

  defp get_bearer_token(client) do
    case client.pre
         |> Enum.find(fn
           {Tesla.Middleware.BearerAuth, _, [[token: _token]]} ->
             true

           _ ->
             false
         end) do
      {_, _, [[token: token]]} ->
        token

      _ ->
        nil
    end
  end

  defp has_middleware?(client, module) do
    client.pre
    |> Enum.any?(fn {mod, _function, _args} ->
      mod == module
    end)
  end

  defp find_middleware(client, module) do
    client.pre
    |> Enum.find(fn {mod, _function, _args} ->
      mod == module
    end)
  end
end
