defmodule Jiraffe.ErrorTest do
  @moduledoc false
  use Jiraffe.Support.TestCase

  doctest Jiraffe.Error

  describe "new/1" do
    test "returns a new Jiraffe.Error struct when given only the reason" do
      assert %Jiraffe.Error{reason: :foo, details: %{}} ==
               Jiraffe.Error.new(:foo)
    end

    test "returns a new Jiraffe.Error struct when given details instead of reason" do
      assert %Jiraffe.Error{reason: :general, details: %{bar: "baz"}} ==
               Jiraffe.Error.new(%{bar: "baz"})
    end
  end

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
