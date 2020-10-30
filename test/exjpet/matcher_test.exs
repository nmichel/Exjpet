
defmodule Exjpet.MatcherTest.Test do
  use Exjpet.Matcher, [
    options: [number_strict_match: true],
    debug: true
  ]

  match "[]", state do
    [:list_empty | state]
  end

  match "[*]", state do
    [:list_any | state]
  end

  match "[true, false]", state do
    [:list_true_false | state]
  end

  match "[null, _]", state do
    [:list_null_any | state]
  end

  match "[_, _, [true, false], true]", state do
    [:t_5 | state]
  end

  match "\"foo\"", state do
    [:t_6 | state]
  end

  match "#\"foo\"", state do
    [:t_7 | state]
  end

  match "42", state do
    [:t_8 | state]
  end

  match "(?<full>[(?<first>_), (?<second>false), *])", state do
    [{:t_9, full, first, second} | state]
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
    assert [:list_any, :list_true_false, {:t_9, [[true, false]], [true], [false]}] = Test.match(node, [])
  end
end
