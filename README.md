# Jiraffe

Jiraffe is an Elixir client library for interacting with Atlassian's Jira REST API.
It provides a convenient way to make requests to Jira for creating, updating, or retrieving issues, among other operations.

# Example

```elixir

# Bearer authentication
{:ok, issue} =
  Jiraffe.client("https://example.atlassian.net", "my-access-token")
  |> Jiraffe.Issues.get("TEST-1")

# Basic authentication
{:ok, issue} =
  Jiraffe.client(
    "https://example.atlassian.net",
    basic: %{username: "test@example.net", password: "secret"}
  ) |> Jiraffe.Issues.get("TEST-1")
```

# Configuration

```elixir
# Log requests (method, url, status, and time)
config :jiraffe, debug: true

# Keep request body and headers
config :jiraffe, keep_request: true

# Set request timeout
config :jiraffe, timeout: 30_000

# Setup retries
config :jiraffe, retry: true

config :jiraffe, retry: [
  delay: 2_000,
  max_retries: 20,
  max_delay: 6_000,
  should_retry: fn
    {:ok, %{status: status}}, _env, %{retries: _retries}
    when status in [429] ->
      true

    _res, _env, _context ->
      false
  end}
]
```

# Testing

### Run tests

```sh
mix test
```

### Run all tests including slow onces

```sh
mix test --include slow
```

### Run tests with coverage

```sh
mix test --cover
```

# License

This project is licensed under the MIT License

# 🚧 Important Notice 🚧

We want to make you aware that this library is currently in its early stages of development and should be considered unstable. 
Until we reach our milestone release of version 1.0.0, please expect the following:

- Rapid Changes: The API, features, and internal implementations may change significantly with each update.
- Limited Support: While we encourage experimentation, we may not be able to provide full support for issues that arise, due to the focus on development.
- Feedback Welcome: We are more than happy to receive feedback and suggestions, which can play a vital role in shaping the library's future.

If you plan to use this library in a production environment or include it as a dependency in a stable project, we recommend waiting for the 1.0.0 release or using it with caution, being prepared to accommodate changes.

Stay tuned for updates, and we look forward to growing with your support and contributions!
