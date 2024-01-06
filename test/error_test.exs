defmodule Jiraffe.ErrorTest do
  @moduledoc false
  use ExUnit.Case

  doctest Jiraffe.Error

  describe "new/2" do
    test "returns a new Jiraffe.Error struct" do
      assert %Jiraffe.Error{reason: :foo, details: %{bar: "baz"}} ==
               Jiraffe.Error.new(:foo, %{bar: "baz"})
    end
  end

  describe "message/1" do
    test "returns a default message" do
      assert "Jira API error" == Jiraffe.Error.message(%Jiraffe.Error{})
    end
  end
end
