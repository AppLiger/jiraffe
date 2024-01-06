# Jiraffe

Jiraffe is an Elixir client library for interacting with Atlassian's Jira REST API.
It provides a convenient way to make requests to Jira for creating, updating, or retrieving issues, among other operations.

# Example

```elixir

{:ok, issue} =
  Jiraffe.client("https://example.atlassian.net", "my-access-token")
  |> Jiraffe.Issue.get("TEST-1")

# Using email and password/token
{:ok, issue} =
  Jiraffe.client(
    "https://example.atlassian.net",
    basic: %{email: "test@example.net", password: "secret"}
  ) |> Jiraffe.Issue.get("TEST-1")
```

# License

This project is licensed under the MIT License
