defmodule Jiraffe.Pagination do
  @moduledoc """
  Defines functions to handle pagination.

  ## Reasoning

  The Jira REST API uses pagination to improve performance.

  Pagination is enforced for operations that could return a large collection of items. When you make a request to a paginated resource, the response wraps the returned array of values in a JSON object with paging metadata.

  For example:

  ```json
  {
    "startAt" : 0,
    "maxResults" : 10,
    "total": 200,
    "isLast": false,
    "values": [
        { /* result 0 */ },
        { /* result 1 */ },
        { /* result 2 */ }
    ]
  }
  ```

    `startAt` is the index of the first item returned in the page.

    `maxResults` is the maximum number of items that a page can return. Each operation can have a different limit for the number of items returned, and these limits may change without notice. To find the maximum number of items that an operation could return, set maxResults to a large number—for example, over 1000—and if the returned value of maxResults is less than the requested value, the returned value is the maximum.

    `total` is the total number of items contained in all pages. This number may change as the client requests the subsequent pages, therefore the client should always assume that the requested page can be empty. Note that this property is not returned for all operations.

    `isLast` indicates whether the page returned is the last one. Note that this property is not returned for all operations.

    See [Reference](https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/#pagination)

  ## Usage
    - Use `use Jiraffe.Pagination` in your module.
    - Define a function that returns a page of results.
    The function should accept a `Jiraffe.Client.t()` and a `Keyword.t()` as arguments and return a `{:ok, page_result()}` or `{:error, Jiraffe.Error.t()}`.
    - In your module, you'll get a function (`all/2`) that returns a list of all results and a function (`stream/2`) that returns a stream of pages.
    - You can customize the names of these functions by passing a list of options to `use Jiraffe.Pagination`:
      - `naming: [[page_fn: :get_page, stream: :stream_name, all: :all_name]]`
      - `page_fn` is the name of the function that returns a page of results.
      - `stream` is the name of the function that returns a stream of pages.
      - `all` is the name of the function that returns a list of all results.
    - You can define multiple resources in the same module by passing a list of options to `use Jiraffe.Pagination`:
      - `naming: [
          [page_fn: :get_users_page, stream: :stream_users, all: :all_users],
          [page_fn: :get_issues_page, stream: :stream_issuers, all: :all_issues]
        ]`


    Example:

    ```elixir
    defmodule PaginatedResource do
      use Jiraffe.Pagination

      def page(_client, _params) do
        {:ok, %{
          start_at: 0,
          max_results: 1,
          total: 2,
          is_last: true,
          values: ["Page 1", "Page 2"]
        }}
      end
    end

    iex> PaginatedResource.all(Jiraffe.client("https://example.atlassian.net", "a-token"), [])
    {:ok, ["Page 1", "Page 2"]}
    ```
  """

  @type page_result() :: %{
          start_at: non_neg_integer(),
          max_results: non_neg_integer(),
          total: non_neg_integer(),
          is_last: boolean(),
          values: [term()]
        }

  defmacro __using__(opts) do
    naming = Keyword.get(opts, :naming, [[]])

    quote do
      unquote(define_functions(naming))
    end
  end

  defp define_functions(naming) when not is_list(naming), do: define_functions([[]])

  defp define_functions(naming) do
    for opts <- naming do
      get_page_fn = Keyword.get(opts, :page_fn, :page)
      stream_name = Keyword.get(opts, :stream, :stream)
      all_name = Keyword.get(opts, :all, :all)

      quote do
        @doc """
        Returns a page of results (see `#{unquote(get_page_fn)}/2` for more info).
        """
        def unquote(:"#{stream_name}")(client, params) do
          Stream.resource(
            fn -> 0 end,
            fn
              page_number when page_number < 0 ->
                {:halt, page_number}

              page_number ->
                per_page = Keyword.get(params, :maxResults, 50)
                pagination_params = [startAt: page_number * per_page, maxResults: per_page]

                params =
                  Keyword.merge(params, pagination_params, fn _key, _v1, v2 -> v2 end)

                case apply(__MODULE__, unquote(get_page_fn), [client, params]) do
                  {:ok, %{is_last: true} = page} -> {[page], -1}
                  {:ok, %{is_last: false} = page} -> {[page], page_number + 1}
                  _ -> {:halt, page_number}
                end
            end,
            & &1
          )
        end

        @doc """
        Returns a list of all results (see `#{unquote(get_page_fn)}/2` for more info).
        """
        def unquote(:"#{all_name}")(client, params) do
          values =
            apply(__MODULE__, unquote(:"#{stream_name}"), [client, params])
            |> Stream.flat_map(fn page -> page.values end)
            |> Enum.to_list()

          {:ok, values}
        end
      end
    end
  end
end
