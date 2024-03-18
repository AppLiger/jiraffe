defmodule Jiraffe.Middleware.Retry do
  @moduledoc """
  Retry request optionally making delays between attempts.

  ## Deciding whether to retry

  By default, this middleware only retries in the case of connection errors (`nxdomain`, `connrefused`, etc).
  Application error checking for retry can be customized through `:should_retry` option.

  ## Delaying retries

  To compute the delay between attemps strategies from `:delay_strategies` are consulted one by one.

  The first non-`nil` result will be used as a delay, so the order of strategies matters.
  If all the strategies return `nil`, or no strategies are configured, no delay between retries is made.

  Each delay strategy module must implement `Jiraffe.Middleware.Retry.Delay` behavior.

  ## Examples

  ```
  defmodule MyClient do
    use Tesla

    plug Jiraffe.Middleware.Retry,
      max_retries: 10,
      delay_strategies: [
        {Jiraffe.Middleware.Retry.Delay.ExponentialBackoff, delay: 500, max_delay: 4_000}
      ],
      should_retry: fn
        {:ok, %{status: status}} when status in [400, 500] -> true
        {:ok, _} -> false
        {:error, _} -> true
      end
    # or
    plug Jiraffe.Middleware.Retry,
      should_retry: fn
        {:ok, %{status: status}}, _env, _context when status in [400, 500] -> true
        {:ok, _reason}, _env, _context -> false
        {:error, _reason}, %Tesla.Env{method: :post}, _context -> false
        {:error, _reason}, %Tesla.Env{method: :put}, %{retries: 2} -> false
        {:error, _reason}, _env, _context -> true
      end
  end
  ```

  ## Options

  - `:delay_strategies` - list of strategies computing the delay between retry attempts
     (list, defaults to an empty list)
  - `:max_retries` - maximum number of retries (non-negative integer, defaults to 5)
  - `:should_retry` - function with an arity of 1 or 3 used to determine if the request should
      be retried; the first argument is the result, the second is the env and the third is
      the context: options + `:retries` (defaults to a match on `{:error, _reason}`)
  """

  @behaviour Tesla.Middleware

  @defaults [
    max_retries: 5
  ]

  @impl Tesla.Middleware
  def call(env, next, opts) do
    opts = opts || []

    context = %{
      retries: 0,
      max_retries: integer_opt!(opts, :max_retries, 0),
      should_retry: should_retry_opt!(opts),
      delay_strategies: delay_strategies_opt!(opts)
    }

    retry(env, next, context)
  end

  # If we have max retries set to 0 don't retry
  defp retry(env, next, %{max_retries: 0}), do: Tesla.run(env, next)

  # If we're on our last retry then just run and don't handle the error
  defp retry(env, next, %{max_retries: max, retries: max}) do
    Tesla.run(env, next)
  end

  # Otherwise we retry if we get a retriable error
  defp retry(env, next, context) do
    res = Tesla.run(env, next)

    {:arity, should_retry_arity} = :erlang.fun_info(context.should_retry, :arity)

    cond do
      should_retry_arity == 1 and context.should_retry.(res) ->
        do_retry(env, next, context)

      should_retry_arity == 3 and context.should_retry.(res, env, context) ->
        do_retry(env, next, context)

      true ->
        res
    end
  end

  defp do_retry(env, next, context) do
    # Find the first non-nil delay
    delay =
      Enum.find_value(context.delay_strategies, fn {module, opts} ->
        apply(module, :compute, [env, context.retries, opts])
      end)

    if delay do
      :timer.sleep(delay)
    end

    context = update_in(context, [:retries], &(&1 + 1))
    retry(env, next, context)
  end

  defp integer_opt!(opts, key, min) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_integer(value) and value >= min -> value
      {:ok, invalid} -> invalid_integer(key, invalid, min)
      :error -> @defaults[key]
    end
  end

  defp should_retry_opt!(opts) do
    case Keyword.get(opts, :should_retry, &match?({:error, _}, &1)) do
      should_retry_fun when is_function(should_retry_fun, 1) ->
        should_retry_fun

      should_retry_fun when is_function(should_retry_fun, 3) ->
        should_retry_fun

      value ->
        invalid_should_retry_fun(value)
    end
  end

  defp delay_strategies_opt!(opts) do
    strategies = Keyword.get(opts, :delay_strategies, [])

    if not is_list(strategies) do
      raise(ArgumentError, "expected :delay_strategies to be a list, got #{inspect(strategies)}")
    end

    Enum.map(strategies, &delay_strategy/1)
  end

  defp delay_strategy({module}), do: delay_strategy({module, []})

  defp delay_strategy({module, opts}) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        if not function_exported?(module, :compute, 3) do
          raise(
            ArgumentError,
            ~s(expected :delay_strategies module "#{module}" to export "compute/3" function)
          )
        end

        {module, opts}

      {:error, error} ->
        raise(
          ArgumentError,
          ~s(expected to be able to load :delay_strategies module "#{module}", got :#{error})
        )
    end
  end

  defp invalid_integer(key, value, min) do
    raise(ArgumentError, "expected :#{key} to be an integer >= #{min}, got #{inspect(value)}")
  end

  defp invalid_should_retry_fun(value) do
    raise(
      ArgumentError,
      "expected :should_retry to be a function with arity of 1 or 3, got #{inspect(value)}"
    )
  end
end
