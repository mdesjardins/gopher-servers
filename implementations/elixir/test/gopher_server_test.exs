defmodule GopherServerTest do
  use ExUnit.Case
  doctest GopherServer

  test "greets the world" do
    assert GopherServer.hello() == :world
  end
end
