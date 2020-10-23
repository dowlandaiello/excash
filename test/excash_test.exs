defmodule ExcashTest do
  use ExUnit.Case
  doctest Excash

  test "greets the world" do
    assert Excash.hello() == :world
  end
end
