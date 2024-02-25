defmodule Jiraffe.Issue.Update do
  @moduledoc false

  alias Jiraffe.{Error, Issue}

  @spec update(
          client :: Jiraffe.Client.t(),
          id :: String.t(),
          body ::
            %{
              optional(:transition) => map(),
              optional(:fields) => map(),
              optional(:update) => map(),
              optional(:history_metadata) => map(),
              optional(:properties) => list(term())
            },
          params :: [
            notify_users: boolean(),
            override_screen_security: boolean(),
            override_editable_flag: boolean(),
            return_issue: boolean(),
            expand: String.t()
          ]
        ) ::
          {:ok, Jiraffe.Issue.t()}
          | {:error, Error.t()}
  def update(client, id, body, params \\ []) do
    params =
      [
        notifyUsers: Keyword.get(params, :notify_users),
        overrideScreenSecurity: Keyword.get(params, :override_screen_security),
        overrideEditableFlag: Keyword.get(params, :override_editable_flag),
        returnIssue: Keyword.get(params, :return_issue),
        expand: Keyword.get(params, :expand)
      ]
      |> Keyword.reject(fn {_, v} -> is_nil(v) end)

    case Jiraffe.put(
           client,
           "/rest/api/2/issue/#{id}",
           Issue.UpdateDetails.new(body),
           query: params
         ) do
      {:ok, %{body: body, status: 200}} ->
        {:ok, Jiraffe.Issue.new(body)}

      {:ok, %{body: _body, status: 204}} ->
        {:ok, %{id: id}}

      {:ok, response} ->
        {:error, Error.new(:cannot_update_issue, response)}

      {:error, reason} ->
        {:error, Error.new(reason)}
    end
  end
end
