defmodule Jiraffe.Middleware.Retry.Delay.RateLimitReset do
  @moduledoc """
  Returns delay computed from the `X-RateLimit-Reset` rate limit header.

  `X-RateLimit-Reset` header indicates the date time when you can retry the request.

  If this header is not present `nil` is returned.

  For detailed explanation of the meaning of this header see
  [Jira documentation](https://developer.atlassian.com/cloud/jira/platform/rate-limiting/#rate-limit-responses).
  """

  @behaviour Jiraffe.Middleware.Retry.Delay

  @datetime_re ~r/^(?<common>\d{4}-\d{2}-\d{2}T\d{2}:\d{2})(?<seconds>:\d{2})?Z$/

  @impl Jiraffe.Middleware.Retry.Delay
  def compute(env, _retries, _options) do
    with header when not is_nil(header) <- Tesla.get_header(env, "x-ratelimit-reset"),
         {:ok, rate_limit_reset} <- parse_datetime(header) do
      NaiveDateTime.diff(
        NaiveDateTime.truncate(rate_limit_reset, :second),
        NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
        :millisecond
      )
    else
      _ -> nil
    end
  end

  defp parse_datetime(string) do
    case Regex.named_captures(@datetime_re, string) do
      nil -> {:error, :invalid_format}
      %{"common" => common, "seconds" => ""} -> NaiveDateTime.from_iso8601("#{common}:00Z")
      _ -> NaiveDateTime.from_iso8601(string)
    end
  end
end
