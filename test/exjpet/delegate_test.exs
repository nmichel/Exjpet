defmodule Exjpet.DelegateTest.Source do
  def echo(what) do
    Atom.to_string(__MODULE__) <> " " <> what
  end
end

defmodule Exjpet.DelegateTest.Target  do
  use Exjpet.Delegate, :"Elixir.Exjpet.DelegateTest.Source"
end

defmodule Exjpet.DelegateTest.Target2  do
  use Exjpet.Delegate, Exjpet.DelegateTest.Source

  def foo() do
    :foo
  end
end

defmodule Exjpet.DelegateTest do
  use ExUnit.Case
  doctest Exjpet.Delegate
  
  test "delegates to Elixir module (atom)" do
    alias Exjpet.DelegateTest.Target
    assert Target.echo("foo") == "Elixir.Exjpet.DelegateTest.Source foo"
  end

  test "delegates to Elixir module (Elixir module)" do
    alias Exjpet.DelegateTest.Target2, as: Target
    assert Target.echo("bar") == "Elixir.Exjpet.DelegateTest.Source bar"
  end

  test "delegate module can contain own function" do
    alias Exjpet.DelegateTest.Target2, as: Target
    assert Target.foo() == :foo
  end
end
