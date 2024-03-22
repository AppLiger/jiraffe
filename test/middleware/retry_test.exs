defmodule Jiraffe.Middleware.RetryTest do
  use Jiraffe.Support.TestCase

  import Mock

  defmodule LaggyAdapter do
    def start_link, do: Agent.start_link(fn -> 0 end, name: __MODULE__)
    def reset(), do: Agent.update(__MODULE__, fn _ -> 0 end)

    def call(env, _opts) do
      Agent.get_and_update(__MODULE__, fn retries ->
        response =
          case env.url do
            "/ok" -> {:ok, env}
            "/maybe" when retries == 2 -> {:error, :nxdomain}
            "/maybe" when retries < 5 -> {:error, :econnrefused}
            "/maybe" -> {:ok, env}
            "/nope" -> {:error, :econnrefused}
            "/retry_status" when retries < 5 -> {:ok, %{env | status: 500}}
            "/retry_status" -> {:ok, %{env | status: 200}}
          end

        {response, retries + 1}
      end)
    end
  end

  defmodule NoDelay do
    @behaviour Jiraffe.Middleware.Retry.Delay

    @impl Jiraffe.Middleware.Retry.Delay
    def compute(_env, _retries, _options), do: nil
  end

  defmodule ConstantDelay do
    @behaviour Jiraffe.Middleware.Retry.Delay

    @impl Jiraffe.Middleware.Retry.Delay
    def compute(_env, _retries, options) do
      Keyword.get(options, :delay)
    end
  end

  defmodule Client do
    use Tesla

    plug(Jiraffe.Middleware.Retry,
      max_retries: 10
    )

    adapter(LaggyAdapter)
  end

  defmodule ClientWithShouldRetryFunction do
    use Tesla

    plug(Jiraffe.Middleware.Retry,
      max_retries: 10,
      should_retry: fn
        {:ok, %{status: status}}, _env, _context when status in [400, 500] ->
          true

        {:ok, _reason}, _env, _context ->
          false

        {:error, _reason}, %Tesla.Env{method: :post}, _context ->
          false

        {:error, _reason}, %Tesla.Env{method: :put}, %{retries: 2} ->
          false

        {:error, _reason}, _env, _context ->
          true
      end
    )

    adapter(LaggyAdapter)
  end

  setup_all do
    {:ok, _pid} = LaggyAdapter.start_link()
    :ok
  end

  setup do
    LaggyAdapter.reset()
    :ok
  end

  setup_with_mocks [
    {:timer, [:passthrough, :unstick], [sleep: fn _time -> :ok end]}
  ] do
    :ok
  end

  test "pass on successful request" do
    assert {:ok, %Tesla.Env{url: "/ok", method: :get}} = Client.get("/ok")
  end

  test "finally pass on laggy request" do
    assert {:ok, %Tesla.Env{url: "/maybe", method: :get}} = Client.get("/maybe")
  end

  test "raise if max_retries is exceeded" do
    assert {:error, :econnrefused} = Client.get("/nope")
  end

  test "use default retry determination function" do
    assert {:ok, %Tesla.Env{url: "/retry_status", method: :get, status: 500}} =
             Client.get("/retry_status")
  end

  test "use custom retry determination function" do
    assert {:ok, %Tesla.Env{url: "/retry_status", method: :get, status: 200}} =
             ClientWithShouldRetryFunction.get("/retry_status")
  end

  test "use custom retry determination function matching on env" do
    assert {:error, :econnrefused} = ClientWithShouldRetryFunction.post("/maybe", "payload")
  end

  test "use custom retry determination function matching on context" do
    assert {:error, :nxdomain} = ClientWithShouldRetryFunction.put("/maybe", "payload")
  end

  test "use default delay strategy list" do
    client = client()

    Tesla.get(client, "/maybe")

    assert [] == timer_sleep_delays()
  end

  test "make no delays between retries if delay strategy list is empty" do
    client = client([])

    Tesla.get(client, "/maybe")

    assert [] == timer_sleep_delays()
  end

  test "make no delays between retries if all delay strategies return nil" do
    client =
      client([
        {NoDelay},
        {ConstantDelay, delay: nil}
      ])

    Tesla.get(client, "/maybe")

    assert [] == timer_sleep_delays()
  end

  test "make delays between retries equal to the first non-nil returned by the strategies" do
    client =
      client([
        {ConstantDelay, delay: nil},
        {ConstantDelay, delay: 1000},
        {NoDelay},
        {ConstantDelay, delay: 2000}
      ])

    Tesla.get(client, "/maybe")

    assert [1000, 1000, 1000, 1000, 1000] == timer_sleep_delays()
  end

  defmodule DefunctClient do
    use Tesla

    plug(Jiraffe.Middleware.Retry)

    adapter(fn _ -> raise "runtime-error" end)
  end

  test "raise in case of unexpected error" do
    assert_raise RuntimeError, fn -> DefunctClient.get("/blow") end
  end

  test "ensures max_retries option is not negative" do
    defmodule ClientWithNegativeMaxRetries do
      use Tesla
      plug(Jiraffe.Middleware.Retry, max_retries: -1)
      adapter(LaggyAdapter)
    end

    assert_raise ArgumentError, "expected :max_retries to be an integer >= 0, got -1", fn ->
      ClientWithNegativeMaxRetries.get("/ok")
    end
  end

  test "ensures should_retry option is a function with arity of 1 or 3" do
    defmodule ClientWithShouldRetryArity0 do
      use Tesla
      plug(Jiraffe.Middleware.Retry, should_retry: fn -> true end)
      adapter(LaggyAdapter)
    end

    defmodule ClientWithShouldRetryArity2 do
      use Tesla
      plug(Jiraffe.Middleware.Retry, should_retry: fn _res, _env -> true end)
      adapter(LaggyAdapter)
    end

    assert_raise ArgumentError,
                 ~r/expected :should_retry to be a function with arity of 1 or 3, got #Function<\d.\d+\/0/,
                 fn ->
                   ClientWithShouldRetryArity0.get("/ok")
                 end

    assert_raise ArgumentError,
                 ~r/expected :should_retry to be a function with arity of 1 or 3, got #Function<\d.\d+\/2/,
                 fn ->
                   ClientWithShouldRetryArity2.get("/ok")
                 end
  end

  test "ensures delay_strategies option is a list" do
    client =
      Tesla.client(
        [
          {Jiraffe.Middleware.Retry, delay_strategies: "foo"}
        ],
        LaggyAdapter
      )

    assert_raise ArgumentError,
                 ~s(expected :delay_strategies to be a list, got "foo"),
                 fn ->
                   Tesla.get(client, "/ok")
                 end
  end

  test "ensures delay_strategies option contains loadable modules" do
    client =
      Tesla.client(
        [
          {Jiraffe.Middleware.Retry, delay_strategies: [{NonExistent, []}]}
        ],
        LaggyAdapter
      )

    assert_raise ArgumentError,
                 ~s(expected to be able to load :delay_strategies module "Elixir.NonExistent", got :nofile),
                 fn ->
                   Tesla.get(client, "/ok")
                 end
  end

  test "ensures delay_strategies option contains modules implementing Retry.Delay behavior" do
    defmodule BadRetry do
    end

    client =
      Tesla.client(
        [
          {Jiraffe.Middleware.Retry, delay_strategies: [{BadRetry, []}]}
        ],
        LaggyAdapter
      )

    assert_raise ArgumentError,
                 ~s(expected :delay_strategies module "Elixir.Jiraffe.Middleware.RetryTest.BadRetry" to export "compute/3" function),
                 fn ->
                   Tesla.get(client, "/ok")
                 end
  end

  defp timer_sleep_delays() do
    for {_, {:timer, :sleep, [delay]}, _} <- call_history(:timer), do: delay
  end

  defp client() do
    Tesla.client([{Jiraffe.Middleware.Retry, []}], LaggyAdapter)
  end

  defp client(strategies) do
    Tesla.client([{Jiraffe.Middleware.Retry, delay_strategies: strategies}], LaggyAdapter)
  end
end
