
defmodule Exjpet.MatcherTest.Test do
  use Exjpet.Matcher, [
    options: [number_strict_match: true],
    reduce: true,
    debug: true
  ]

  match "[]" do
    :list_empty
  end

  match "[*]" do
    :list_any
  end

  match "[true, false]" do
    :list_true_false
  end

  match "[null, _]" do
    :list_null_any
  end

  match "[_, _, [true, false], true]" do
    :t_5
  end

  match "\"foo\"" do
    :t_6
  end

  match "#\"foo\"" do
    :t_7
  end

  match "42" do
    :t_8
  end

  match "(?<full>[(?<first>_), (?<second>false), *])" do
    {:t_9, full, first, second}
  end

  # @pattern "[" <> "]"
  # match @pattern, %{state: :list} do
  #   # Some non sense code
  #   Stream.cycle([:ok, 42, "coucou", jnode])
  #   |> Stream.take(10)
  #   |> Enum.map(&inspect/1)
  #   |> Enum.join(",")
  # end
  # match @pattern, state do
  #   IO.puts("[] default")
  #   state
  # end

  # @pattern ["(?<val>[", "*", "])"] |> Enum.join("")
  # match @pattern, _ do
  #   IO.puts("I say #{inspect(jnode)} #{inspect(captures)} #{val}")
  #   :ok
  # end

  # @pattern "[*, (?<val>_)]"
  # match @pattern do
  #   IO.puts("say I #{inspect(jnode)} #{inspect(captures)} #{val}")
  #   :ok
  # end

  # match "43", _ do
  #   IO.puts("my name is prout #{inspect(jnode)}")
  #   :ok
  # end
end


defmodule Exjpet.MatcherTest do
  use ExUnit.Case
  doctest Exjpet.Matcher

  alias Exjpet.MatcherTest.Test

  test "test" do
    node = Poison.decode!("[true, false]")
    assert [{:t_9, [[true, false]], [true], [false]}, :no_match, :no_match, :no_match, :no_match, :no_match, :list_true_false, :list_any, :no_match] = Test.match(node, [])
  end
end
