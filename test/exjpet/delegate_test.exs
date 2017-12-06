defmodule Exjpet.DelegateTest do
  use ExUnit.Case
  doctest Exjpet.Delegate

  defmodule Source do
    def echo(what) do
      Atom.to_string(__MODULE__) <> " " <> what
    end
  end

  test "delegates to Elixir module (atom)" do
    defmodule Target1  do
      use Exjpet.Delegate, :"Elixir.Exjpet.DelegateTest.Source"
    end

    alias Target1, as: Target
    assert Target.echo("foo") == "Elixir.Exjpet.DelegateTest.Source foo"
  end

  test "delegates to Elixir module (Elixir module)" do
    defmodule Target2 do
      use Exjpet.Delegate, Exjpet.DelegateTest.Source
    end

    assert Target2.echo("bar") == "Elixir.Exjpet.DelegateTest.Source bar"
  end

  test "delegate module can contain own function" do
    defmodule Target3 do
      use Exjpet.Delegate, Exjpet.DelegateTest.Source

      def foo() do
        :foo
      end
    end

    assert Target3.foo() == :foo
  end
end
