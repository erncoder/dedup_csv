defmodule DedupCSVTest do
  use ExUnit.Case
  alias DedupCSV, as: TestMe

  doctest TestMe

  test "greets the world" do
    assert DedupCsv.hello() == :world
  end
end
