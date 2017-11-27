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

  test "Exjpet.compile/2"
  test "Exjpet.run/2"
  test "Exjpet.backend/2"

  test "validation tests" do
    {:ok, resp} = HTTPoison.get("https://gist.githubusercontent.com/nmichel/8b0d6f194e89abb7281d/raw/907027e8d0be034433e1f56661a6a4fa3292daff/validation_tests.json")
    test_descs = :poison.decode(resp.body)

    for %{"pattern" => pattern, "tests" => tests} <- test_descs do
      IO.puts "* pattern  #{inspect pattern}"
      matcher = :ejpet.compile(pattern, :poison)
      Enum.each(tests, &do_test(matcher, &1))
    end
  end

  defp do_test(matcher, %{"inject" => inject, "captures" => captures, "node" => node, "status" => status}) do
    node_text = :poison.encode(node)
    IO.puts "node_text  #{inspect node_text}"
    node_backend = :ejpet.decode(node_text, :ejpet.backend(matcher))
    IO.puts "node_backend  #{inspect node_backend}"
    {s, caps} = :ejpet.run(node_backend, matcher, inject)
    IO.puts "{s, caps}  #{inspect s} #{inspect caps}"
    real_c = :ejpet.decode(:ejpet.encode(caps, :ejpet.backend(matcher)), :ejpet.backend(matcher))
    reencoded_exp_c = :ejpet.decode(:ejpet.encode(captures, :poison), :ejpet.backend(matcher))
    assert {s, real_c} == {status, reencoded_exp_c}
  end
  defp do_test(matcher, test) do
    do_test(matcher, Map.put(test, "inject", []))
  end
end
