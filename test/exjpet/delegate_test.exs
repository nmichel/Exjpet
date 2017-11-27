defmodule Exjpet.DelegateTest.Source do
  def echo(what) do
    Atom.to_string(__MODULE__) <> " " <> what
  end

  def bar do
    Atom.to_string(__MODULE__) <> " bar"
  end
end

defmodule Exjpet.DelegateTest.Target  do
  use Exjpet.Delegate, :'Elixir.Exjpet.DelegateTest.Source'
end

defmodule Exjpet.DelegateTest do
  use ExUnit.Case
  doctest Exjpet.Delegate
  
  test "Target delegates to Source" do
    alias Exjpet.DelegateTest.Target
    assert Target.echo("foo") == "Elixir.Exjpet.DelegateTest.Source foo"
  end
end
