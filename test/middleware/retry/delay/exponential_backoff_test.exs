defmodule Jiraffe.Middleware.Retry.Delay.ExponentialBackoffTest do
  use Jiraffe.Support.TestCase

  import Jiraffe.Middleware.Retry.Delay.ExponentialBackoff

  test "returns base delay on the first retry attempt" do
    options = [delay: 100, max_delay: 2_000, jitter_factor: 0.0]

    assert Keyword.get(options, :delay) == compute(%Tesla.Env{}, 0, options)
  end

  test "returns exponentially increasing delay with each retry attempt" do
    options = [delay: 10, max_delay: 2_000, jitter_factor: 0.0]

    Enum.each(1..7, fn retries ->
      delay = Keyword.get(options, :delay) * Bitwise.bsl(1, retries)

      assert delay == compute(%Tesla.Env{}, retries, options)
    end)
  end

  test "returns delay capped by max delay" do
    options = [delay: 100, max_delay: 2_000, jitter_factor: 0.0]

    assert Keyword.get(options, :max_delay) == compute(%Tesla.Env{}, 50, options)
  end

  test "returns delay with jitter applied" do
    options = [delay: 100, max_delay: 2_000, jitter_factor: 0.2]

    lower_bound = Keyword.get(options, :delay) * (1 - Keyword.get(options, :jitter_factor))
    upper_bound = Keyword.get(options, :delay)

    delays = for _ <- 1..100, do: compute(%Tesla.Env{}, 0, options)

    assert Enum.all?(delays, &(lower_bound <= &1 and &1 <= upper_bound))
    assert 100 > delays |> Enum.frequencies() |> map_size(), "delays must not be all the same"
  end

  test "ensures delay option is positive" do
    assert_raise ArgumentError, "expected :delay to be an integer >= 1, got 0", fn ->
      compute(%Tesla.Env{}, 0, delay: 0)
    end
  end

  test "ensures delay option is an integer" do
    assert_raise ArgumentError, "expected :delay to be an integer >= 1, got 0.25", fn ->
      compute(%Tesla.Env{}, 0, delay: 0.25)
    end
  end

  test "ensures max_delay option is positive" do
    assert_raise ArgumentError, "expected :max_delay to be an integer >= 1, got -1", fn ->
      compute(%Tesla.Env{}, 0, max_delay: -1)
    end
  end

  test "ensures max_delay option is an integer" do
    assert_raise ArgumentError, ~s(expected :max_delay to be an integer >= 1, got "500"), fn ->
      compute(%Tesla.Env{}, 0, max_delay: "500")
    end
  end

  test "ensures jitter_factor option is a float between 0 and 1" do
    assert_raise ArgumentError,
                 "expected :jitter_factor to be a float >= 0 and <= 1, got -0.1",
                 fn ->
                   compute(%Tesla.Env{}, 0, jitter_factor: -0.1)
                 end

    assert_raise ArgumentError,
                 "expected :jitter_factor to be a float >= 0 and <= 1, got 1.1",
                 fn ->
                   compute(%Tesla.Env{}, 0, jitter_factor: 1.1)
                 end

    assert_raise ArgumentError,
                 ~s(expected :jitter_factor to be a float >= 0 and <= 1, got "0.1"),
                 fn ->
                   compute(%Tesla.Env{}, 0, jitter_factor: "0.1")
                 end
  end
end
