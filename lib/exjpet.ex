defmodule Exjpet do
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

  :ejpet.module_info[:exports]
  |> Kernel.--([{:module_info, 0}, {:module_info, 1}])
  |> Enum.each(fn
    ({name, 0}) ->
      def unquote(name)(), do: :ejpet.unquote(name)()
    ({name, 1}) ->
      def unquote(name)(a), do: :ejpet.unquote(name)(a)
    ({name, 2}) ->
      def unquote(name)(a, b), do: :ejpet.unquote(name)(a, b)
    ({name, 3}) ->
      def unquote(name)(a, b, c), do: :ejpet.unquote(name)(a, b, c)
    ({name, 4}) ->
      def unquote(name)(a, b, c, d), do: :ejpet.unquote(name)(a, b, c, d)
    end)
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
