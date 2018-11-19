defmodule PanpipeTest do
  use ExUnit.Case
  doctest Panpipe

  test "greets the world" do
    assert Panpipe.hello() == :world
  end
end
