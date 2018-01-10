defmodule Exjpet do
  use Exjpet.Delegate, to: :ejpet, except: [compile: 1]

  @moduledoc """
  Documentation for Exjpet.

  ## Examples

      iex> epm = Exjpet.compile("[1, *, (?<cap>{})]", :poison)
      iex> json = Exjpet.decode("[1, 2, {\\\"a\\\": 42}]", :poison)
      iex> Exjpet.run(json, epm)
      {true, %{"cap" => [%{"a" => 42}]}}
  """

  @doc """
  Compile `expr` with `Poison` as JSON codec.

  Same as Exjpet.compile(expr, :poison)

      iex> epm = Exjpet.compile "[*]"
      iex> Exjpet.backend epm
      :poison
  """
  def compile(expr) do
    compile(expr, :poison)
  end
end

defmodule :ejpet_poison_generators do
  @moduledoc false

  defdelegate generate_matcher(a, b, c), to: :ejpet_jsone_generators
end

defmodule :poison do
  @moduledoc false

  def decode(text) do
    {:ok, json} = Poison.decode(text)
    json
  end

  def encode(json) do
    {:ok, text} = Poison.encode(json)
    text
  end
end
