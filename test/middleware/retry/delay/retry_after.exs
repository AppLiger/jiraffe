defmodule Jiraffe.Middleware.Retry.Delay.RetryAfterTest do
  use ExUnit.Case

  import Jiraffe.Middleware.Retry.Delay.RetryAfter

  test "returns Retry-After header's value times 1000 if it can be parsed to a non-negative integer" do
    header_values = [
      {"0", 0},
      {"12", 12_000}
    ]

    Enum.each(header_values, fn {header, delay} ->
      env = %Tesla.Env{headers: [{"retry-after", header}]}

      assert delay == compute(env, 0, [])
    end)
  end

  test "returns nil if Retry-After header is missing" do
    env = %Tesla.Env{}

    assert nil == compute(env, 0, [])
  end

  test "returns nil if Retry-After header's value cannot be parsed to a non-negative integer" do
    bad_header_values = [
      "foo",
      "12.0",
      "12.3",
      "-12"
    ]

    Enum.each(bad_header_values, fn header ->
      env = %Tesla.Env{headers: [{"retry-after", header}]}

      assert nil == compute(env, 0, [])
    end)
  end
end
