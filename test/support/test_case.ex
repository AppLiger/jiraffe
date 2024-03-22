defmodule Jiraffe.Support.TestCase do
  @moduledoc """
  Helpers for defining Jiraffe test cases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Tesla.Mock, except: [mock: 1]
      import Jiraffe.Support.TestHelpers
    end
  end
end
