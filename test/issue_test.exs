defmodule Jiraffe.IssueTest do
  @moduledoc false
  use Jiraffe.Support.TestCase

  doctest Jiraffe.Issue

  describe "new/1" do
    test "returns a new issue with the given fields" do
      assert %Jiraffe.Issue{
               fields: %{
                 "description" => "Bar",
                 "summary" => "Foo"
               }
             } ==
               Jiraffe.Issue.new(%{
                 "fields" => %{
                   "summary" => "Foo",
                   "description" => "Bar"
                 }
               })
    end
  end
end
