defmodule Exjpet do
  use Exjpet.Delegate, to: :ejpet, except: [compile: 1]

  @default_codec :poison

  @moduledoc """
  Documentation for Exjpet.

  ## Examples

      iex> epm = Exjpet.compile("[1, *, (?<cap>{})]")
      iex> json = Exjpet.decode(~s([1, 2, {"a": 42}]), :poison)
      iex> Exjpet.run(json, epm)
      {true, %{"cap" => [%{"a" => 42}]}}
  """

  @doc """
  Compile `expr` with `Poison` as JSON codec.

  Same as `Exjpet.compile(expr, :poison)`

      iex> epm = Exjpet.compile "[*]"
      iex> Exjpet.backend epm
      :poison
  """
  def compile(expr) do
    compile(expr, @default_codec)
  end

  @doc """
  Decode string `str` using `Poison`.

  Same as `Exjpet.decode(str, :poison)`

      iex> Exjpet.decode ~s({"foo": 42})
      %{"foo" => 42}
  """
  def decode(str) do
    decode(str, @default_codec)
  end

  @doc """
  Encode JSON document `json` using `Poison`.

  Same as `Exjpet.encode(json, :poison)`

      iex> Exjpet.encode %{foo: 42 }
      "{\\\"foo\\\":42}"
  """
  def encode(json) do
    encode(json, @default_codec)
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
