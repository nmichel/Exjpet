defmodule Exjpet do
  use Exjpet.Delegate, :ejpet

  @moduledoc """
  Documentation for Exjpet.
  """

  @doc """

  ## Examples

      iex> epm = Exjpet.compile("[1, *, (?<cap>{})]", :poison)
      iex> json = Exjpet.decode("[1, 2, {\\\"a\\\": 42}]", :poison)
      iex> Exjpet.run(json, epm)
      {true, [{"cap", [%{"a" => 42}]}]}
  """
end

defmodule :ejpet_poison_generators do
  defdelegate generate_matcher(a, b, c), to: :ejpet_jsone_generators
end

defmodule :poison do
  def decode(text) do
    {:ok, json} = Poison.decode(text)
    json
  end

  def encode(json) do
    {:ok, text} = Poison.encode(json)
    text
  end
end
