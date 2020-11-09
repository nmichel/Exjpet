
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

  match "{}", state do
    [:object_any | state]
  end

  match ~s({"foo":_}), state do
    [:object_key_any_value | state]
  end

  match ~s({_: [42]}), state do
    [:object_any_key_value | state]
  end

  match ~s({_: [42], _: false, "foo": _}), state do
    [:object_many_conds | state]
  end

  match ~s({"foo": [42]}), state do
    [:object_key_and_value | state]
  end

  match ~s{(?<cap>false)}, state do
    [captures | state]
  end

  match ~s(<>), state do
    [:iterable_any]
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
    assert [:list_any, :list_true_false, {:t_9, [[true, false]], [true], [false]}, :iterable_any] == Test.match(node, [])
  end

  test "match any object" do
    assert [:object_any, :iterable_any] == Test.match(Poison.decode!("{}"), [])
  end

  test "match object by key" do
    assert [:object_any, :object_key_any_value, :iterable_any] == Test.match(Poison.decode!(~s({"foo": 42})), [])
    assert [:object_any, :object_key_any_value, :iterable_any] == Test.match(Poison.decode!(~s({"foo": []})), [])
    assert [:object_any, :iterable_any] == Test.match(Poison.decode!(~s({"notfoo": 42})), [])
  end

  test "match object by value" do
    assert [:object_any, :object_key_any_value, :object_any_key_value, :object_key_and_value, :iterable_any] == Test.match(Poison.decode!(~s({"foo": [42]})), [])
    assert [:object_any, :object_any_key_value, :iterable_any] == Test.match(Poison.decode!(~s({"other_key": [42]})), [])
    assert [:object_any, :iterable_any] == Test.match(Poison.decode!(~s({"notfoo": 42})), [])
  end

  test "match object by key and value" do
    assert [:object_any, :object_key_any_value, :object_any_key_value, :object_key_and_value, :iterable_any] == Test.match(Poison.decode!(~s({"foo": [42]})), [])
  end

  test "match object several conditions" do
    assert [:object_any, :object_key_any_value, :object_any_key_value, :object_many_conds, :object_key_and_value, :iterable_any] == Test.match(Poison.decode!(~s({"foo": [42], "bar": false})), [])
    assert [:object_any, :object_key_any_value, :object_any_key_value, :object_many_conds, :iterable_any] == Test.match(Poison.decode!(~s({"tsoin": [42], "bar": false, "foo": {}})), [])
    refute [:object_any, :object_key_any_value, :object_any_key_value, :object_many_conds, :iterable_any] == Test.match(Poison.decode!(~s({"tsoin": [42], "bar": true, "foo": {}})), [])
  end

  test "capture" do
    assert [%{"cap" => [false]}] == Test.match(Poison.decode!(~s(false)), [])
  end

  test "iterable" do
    assert [:list_empty, :list_any, :iterable_any] == Test.match(Poison.decode!(~s([])), [])
  end
end
