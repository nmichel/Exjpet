defmodule Exjpet.DelegateTest do
  use ExUnit.Case
  doctest Exjpet.Delegate

  defmodule Source do
    def echo(what) do
      "#{inspect __MODULE__}.echo(#{inspect what})"
    end

    def neh(bi \\ "bi", bu \\ "bu")

    def neh(bi, bu) do
      "#{inspect __MODULE__}.neh(#{inspect bi}, #{inspect bu})"
    end
  end

  test "delegates to Elixir module (atom)" do
    defmodule Target1  do
      use Exjpet.Delegate, to: :"Elixir.Exjpet.DelegateTest.Source"
    end

    alias Target1, as: Target
    assert Target.echo("foo") == ~s{Exjpet.DelegateTest.Source.echo("foo")}
  end

  test "delegates to Elixir module (Elixir module)" do
    defmodule Target2 do
      use Exjpet.Delegate, to: Exjpet.DelegateTest.Source
    end

    assert Target2.echo("bar") == ~s{Exjpet.DelegateTest.Source.echo("bar")}
  end

  test "delegate module can contain own function" do
    defmodule Target3 do
      use Exjpet.Delegate, to: Exjpet.DelegateTest.Source

      def foo() do
        :foo
      end
    end

    assert Target3.foo() == :foo
  end

  test "can exclude some functions/arities" do
    defmodule Target3 do
      use Exjpet.Delegate, to: Exjpet.DelegateTest.Source, except: [neh: 0, neh: 2]

      def foo() do
        :foo
      end
    end

    assert Target3.foo() == :foo
    refute Enum.member?(Target3.__info__(:functions), {:neh, 0})
    assert Enum.member?(Target3.__info__(:functions), {:neh, 1})
    refute Enum.member?(Target3.__info__(:functions), {:neh, 2})
  end
end
