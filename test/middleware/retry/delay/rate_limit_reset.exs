defmodule Jiraffe.Middleware.Retry.Delay.RateLimitResetTest do
  use ExUnit.Case, async: false

  import Jiraffe.Middleware.Retry.Delay.RateLimitReset

  import Mock

  setup_with_mocks [
    {NaiveDateTime, [:passthrough], utc_now: fn -> ~N[2024-01-01 13:00:00] end}
  ] do
    :ok
  end

  test "returns delay in milliseconds till X-RateLimit-Reset header's value" do
    header_values = [
      {"2024-01-01T13:03:45Z", (3 * 60 + 45) * 1000},
      {"2024-01-01T13:03:00Z", 3 * 60 * 1000},
      {"2024-01-01T13:03Z", 3 * 60 * 1000}
    ]

    Enum.each(header_values, fn {header, delay} ->
      env = %Tesla.Env{headers: [{"x-ratelimit-reset", header}]}

      assert delay == compute(env, 0, [])
    end)
  end

  test "returns nil if X-RateLimit-Reset header is missing" do
    env = %Tesla.Env{}

    assert nil == compute(env, 0, [])
  end

  test "returns nil if X-RateLimit-Reset header's value cannot be parsed to a datetime" do
    bad_header_values = [
      "tomorrow",
      "12.0",
      "12.3",
      "2024-01-01T13:34:56",
      "2024-01-01T13:34",
      "2024-01-01T13Z",
      "-12"
    ]

    Enum.each(bad_header_values, fn header ->
      env = %Tesla.Env{headers: [{"retry-after", header}]}

      assert nil == compute(env, 0, [])
    end)
  end
end
