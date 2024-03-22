defmodule Jiraffe.Middleware.Retry.Delay do
  @moduledoc """
  Represents a strategy to compute the delay between retry attempts.

  The computation is made based on the request parameters and the number
  of attempts made so far.
  """

  @doc """
  Computes the time in milliseconds to wait between consequent retry attempts.

  Before calling this function some `retries` could have already been made.

  If the result cannot be determined by this strategy, `nil` is returned.
  """
  @callback compute(env :: Tesla.Env.t(), retries :: non_neg_integer(), options :: Keyword.t()) ::
              non_neg_integer() | nil
end
