defmodule JiraffeTest do
  use ExUnit.Case
  doctest Jiraffe

  test "greets the world" do
    assert Jiraffe.hello() == :world
  end
end
