defmodule ExjpetTest do
  use ExUnit.Case
  doctest Exjpet

  test "decode with :poison.decode/1" do
    text = "[1, 2, 3]"
    {:ok, json} = Poison.decode(text)
    assert :poison.decode(text) == json
  end

  test "encode with :poison.encode/1" do
    json = [1, 2, 3, %{a: 42}]
    {:ok, text} = Poison.encode(json)
    assert :poison.encode(json) == text
  end
end
