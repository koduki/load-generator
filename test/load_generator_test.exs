defmodule LoadGeneratorTest do
  use ExUnit.Case
  doctest LoadGenerator

  test "greets the world" do
    assert LoadGenerator.hello() == :world
  end
end
