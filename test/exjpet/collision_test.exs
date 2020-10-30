defmodule Exjpet.CollisionTest do
  use ExUnit.Case

  defmodule One do
    use Exjpet.Matcher

    match ~s{(?<what>"coucou")}, _ do
      {__MODULE__, what}
    end
  end

  defmodule Other do
    use Exjpet.Matcher

    match ~s{(?<what>"coucou")}, _ do
      {__MODULE__, what}
    end
  end

  test "Generated functions do not collide " do
    assert {One, ["coucou"]} == One.match(Poison.decode!(~s("coucou")), [])
    assert {Other, ["coucou"]} == Other.match(Poison.decode!(~s("coucou")), [])
  end
end
