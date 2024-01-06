defmodule JiraffeTest do
  @moduledoc false
  use ExUnit.Case
  doctest Jiraffe

  import Tesla.Mock

  @expected_client_with_bearer_auth %Tesla.Client{
    fun: nil,
    pre: [
      {Tesla.Middleware.BaseUrl, :call, ["https://example.atlassian.net"]},
      {Tesla.Middleware.JSON, :call, [[]]},
      {Tesla.Middleware.Headers, :call, [[{"authorization", "Bearer a-token"}]]}
    ],
    post: [],
    adapter: nil
  }

  @expected_client_with_basic_auth %Tesla.Client{
    fun: nil,
    pre: [
      {Tesla.Middleware.BaseUrl, :call, ["https://example.atlassian.net"]},
      {Tesla.Middleware.JSON, :call, [[]]},
      {Tesla.Middleware.Headers, :call,
       [[{"authorization", "Basic dXNlckBleGFtcGxlLm5ldDphLXRva2Vu"}]]}
    ],
    post: [],
    adapter: nil
  }

  describe "client/2 with a valid Base URL and a Token" do
    test "returns a Tesla client with correct Base URL, Bearer Authorization headers and adapter" do
      client = Jiraffe.client("https://example.atlassian.net", "a-token")

      assert client == @expected_client_with_bearer_auth
    end
  end

  describe "client/2 with a valid Base URL and a Personal Access Token" do
    test "returns a Tesla client with correct Base URL and Bearer Authorization headers" do
      client = Jiraffe.client("https://example.atlassian.net", personal_access_token: "a-token")

      assert client == @expected_client_with_bearer_auth
    end
  end

  describe "client/2 with a valid Base URL and a OAuth2 Access Token" do
    test "returns a Tesla client with correct Base URL and Bearer Authorization headers" do
      client = Jiraffe.client("https://example.atlassian.net", oauth2: %{access_token: "a-token"})

      assert client == @expected_client_with_bearer_auth
    end
  end

  describe "client/2 with a valid Base URL, Email and Token" do
    test "returns a Tesla client with correct Base URL and Basic Authorization headers" do
      client =
        Jiraffe.client("https://example.atlassian.net",
          basic: %{email: "user@example.net", token: "a-token"}
        )

      assert client == @expected_client_with_basic_auth
    end
  end

  describe "client/2 with a valid Base URL, Username and Password" do
    test "returns a Tesla client with correct Base URL and Basic Authorization headers" do
      client =
        Jiraffe.client("https://example.atlassian.net",
          basic: %{username: "user@example.net", password: "a-token"}
        )

      assert client == @expected_client_with_basic_auth
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
end
