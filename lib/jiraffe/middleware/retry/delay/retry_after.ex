defmodule Jiraffe.Middleware.Retry.Delay.RetryAfter do
  @moduledoc """
  Returns delay computed from the `Retry-After` rate limit header.

  `Retry-After` header indicates how many seconds the app must wait before reissuing the request.

  If this header is not present `nil` is returned.

  For detailed explanation of the meaning of this header see
  [Jira documentation](https://developer.atlassian.com/cloud/jira/platform/rate-limiting/#rate-limit-responses).
  """

  @behaviour Jiraffe.Middleware.Retry.Delay

  @impl Jiraffe.Middleware.Retry.Delay
  def compute(env, _retries, _options) do
    with header when not is_nil(header) <- Tesla.get_header(env, "retry-after"),
         {:ok, retry_after} <- parse_non_neg_integer(header) do
      retry_after * 1000
    else
      _ -> nil
    end
  end

  defp parse_non_neg_integer(string) do
    case Integer.parse(string) do
      {value, ""} when value >= 0 -> {:ok, value}
      _ -> {:error, :invalid_format}
    end
  end
end
