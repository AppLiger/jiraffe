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

  describe "stream_pages/2" do
    setup do
      client = Jiraffe.client("https://example.atlassian.net", "a-token")

      mock(fn
        %{
          url: "https://example.atlassian.net/test",
          query: [startAt: 0, maxResults: 1]
        } ->
          json(
            %{
              startAt: 0,
              maxResults: 1,
              isLast: false,
              total: 2,
              values: ["Page 1: A", "Page 1: B"]
            },
            status: 200
          )

        %{
          url: "https://example.atlassian.net/test",
          query: [startAt: 1, maxResults: 1]
        } ->
          json(
            %{
              startAt: 1,
              maxResults: 1,
              isLast: true,
              total: 2,
              values: ["Page 2: A", "Page 2: B"]
            },
            status: 200
          )

        %{
          url: "https://example.atlassian.net/test-no-page-info",
          query: [startAt: 0, maxResults: 1]
        } ->
          json(
            %{
              values: ["Page 1: A", "Page 1: B"]
            },
            status: 200
          )

        %{url: "https://example.atlassian.net/test"} = asdf ->
          json(%{foo: "bar"}, status: 200)
      end)

      {:ok, client: client}
    end

    test "returns a stream of pages", %{client: client} do
      assert [
               %{
                 "isLast" => false,
                 "maxResults" => 1,
                 "startAt" => 0,
                 "total" => 2,
                 "values" => ["Page 1: A", "Page 1: B"]
               },
               %{
                 "isLast" => true,
                 "maxResults" => 1,
                 "startAt" => 1,
                 "total" => 2,
                 "values" => ["Page 2: A", "Page 2: B"]
               }
             ] ==
               Jiraffe.stream_pages(
                 fn pagination_params ->
                   case Jiraffe.get(client, "/test", query: pagination_params) do
                     {:ok, %{body: body}} -> {:ok, body}
                     {:error, error} -> {:error, error}
                   end
                 end,
                 1
               )
               |> Enum.to_list()
    end

    test "returns empty stream if result has no pagination info", %{client: client} do
      assert [] ==
               Jiraffe.stream_pages(
                 fn pagination_params ->
                   case Jiraffe.get(client, "/test-no-page-info", query: pagination_params) do
                     {:ok, %{body: body}} -> {:ok, body}
                     {:error, error} -> {:error, error}
                   end
                 end,
                 1
               )
               |> Enum.to_list()
    end
  end
end
