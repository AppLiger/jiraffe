defmodule Jiraffe.Support.TestCase do
  @moduledoc """
  Helpers for defining Jiraffe test cases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Tesla.Mock
      import Jiraffe.Support.TestHelpers
    end
  end
end
