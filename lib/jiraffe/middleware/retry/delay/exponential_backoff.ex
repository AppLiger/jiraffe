defmodule Jiraffe.Middleware.Retry.Delay.ExponentialBackoff do
  @moduledoc """
  Retry using exponential backoff and full jitter.

  ## Backoff algorithm

  The backoff algorithm optimizes for tight bounds on completing a request successfully.
  It does this by first calculating an exponential backoff factor based on the
  number of retries that have been performed.  It then multiplies this factor against
  the base delay. The total maximum delay is found by taking the minimum of either
  the calculated delay or the maximum delay specified. This creates an upper bound
  on the maximum delay we can see.

  In order to find the actual delay value we apply additive noise which is proportional
  to the current desired delay. This ensures that the actual delay is kept within
  the expected order of magnitude, while still having some randomness, which ensures
  that our retried requests don't "harmonize" making it harder for the downstream service to heal.

  ## Options

  - `:delay` - base delay in milliseconds (positive integer, defaults to 50)
  - `:max_delay` - maximum delay in milliseconds (positive integer, defaults to 5000)
  - `:jitter_factor` - additive noise proportionality constant
      (float between 0 and 1, defaults to 0.2)
  """

  @behaviour Jiraffe.Middleware.Retry.Delay

  @defaults [
    delay: 50,
    max_delay: 5_000,
    jitter_factor: 0.2
  ]

  @impl Jiraffe.Middleware.Retry.Delay
  @spec compute(env :: Tesla.Env.t(), retries :: non_neg_integer(), options :: Keyword.t()) ::
          non_neg_integer() | nil
  def compute(_env, retries, options) do
    cap = integer_opt!(options, :max_delay, 1)
    base = integer_opt!(options, :delay, 1)
    jitter_factor = float_opt!(options, :jitter_factor, 0, 1)

    factor = Bitwise.bsl(1, retries)
    max_sleep = min(cap, base * factor)

    # This ensures that the delay's order of magnitude is kept intact, while still having some jitter.
    # Generates a value x where 1 - jitter_factor <= x <= 1
    jitter = 1 - jitter_factor * :rand.uniform()

    # The actual delay is in the range max_sleep * (1 - jitter_factor) <= delay <= max_sleep
    trunc(max_sleep * jitter)
  end

  defp integer_opt!(opts, key, min) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_integer(value) and value >= min -> value
      {:ok, invalid} -> invalid_integer(key, invalid, min)
      :error -> @defaults[key]
    end
  end

  defp float_opt!(opts, key, min, max) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_float(value) and value >= min and value <= max -> value
      {:ok, invalid} -> invalid_float(key, invalid, min, max)
      :error -> @defaults[key]
    end
  end

  defp invalid_integer(key, value, min) do
    raise(ArgumentError, "expected :#{key} to be an integer >= #{min}, got #{inspect(value)}")
  end

  defp invalid_float(key, value, min, max) do
    raise(
      ArgumentError,
      "expected :#{key} to be a float >= #{min} and <= #{max}, got #{inspect(value)}"
    )
  end
end
