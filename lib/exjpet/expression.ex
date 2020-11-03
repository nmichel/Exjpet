defmodule Exjpet.Expression do
  @moduledoc """
  Matching expressions may be uneasy to write. This module provides a set of
  macros that may be helpful.

  ## Examples

      iex> list([:some, 1, 2, :any])
      "[*,1,2,_]"
      iex> object()
      "{}"
      iex> object(with_value: capture(:any, as: "foo"))
      "{_:(?<foo>_)}"
  """

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  Generate a list matching expression.

  ## Examples

      iex> list([1, 2])
      "[1,2]"
  """
  defmacro list(entries \\ [])

  defmacro list(entries) do
    entries = Enum.map(entries, &transform/1)
    quote do
      "[" <> Enum.join(unquote(entries), ",") <> "]"
    end
  end

  @doc """
  Generate a object matching expression.

  ## Examples

      iex> object(with_value: 42, with_key: "foo")
      "{_:42,\\\"foo\\\":_}"
      iex> object(with_value: object(with: [key: "neh", value: 42]), with_key: "foo")
      "{_:{\\\"neh\\\":42},\\\"foo\\\":_}"
  """
  defmacro object(constraints \\ [])

  defmacro object(constraints) do
    constraints = Enum.map(constraints, &transform/1)
    quote do
      "{" <> Enum.join(unquote(constraints), ",") <> "}"
    end
  end

  @doc """
  Generate a capture matching expression.

  ## Examples

      iex> capture(object(), as: :val)
      "(?<val>{})"
      iex> capture(object(), as: "val")
      "(?<val>{})"
  """
  defmacro capture(frag, opts)

  defmacro capture(frag, [as: name]) when is_atom(name) do
    quote do
      capture(unquote(frag), [as: unquote(to_string(name))])
    end
  end
  defmacro capture(frag, [as: name]) do
    quote do
      "(?<" <> unquote(name) <> ">" <> unquote(transform(frag)) <> ")"
    end
  end

  @doc """
  Generate a set matching expression.

  ## Examples

      iex> set([42])
      "<42>"
      iex> set([42], [global: true])
      "<42>/g"
      iex> set([object()], [deep: true])
      "<!{}!>"
      iex> set([object()], [deep: true, global: true])
      "<!{}!>/g"
  """
  defmacro set(constraints \\ [], modifiers \\ [])

  defmacro set(constraints, modifiers) do
    modifiers = Keyword.merge(default_modifiers(), modifiers)
    {:ok, deep?} = Keyword.fetch(modifiers, :deep)
    {:ok, global?} = Keyword.fetch(modifiers, :global)
    constraints = Enum.map(constraints, &transform/1)

    quote bind_quoted: [constraints: constraints,
                        deep?:       deep?,
                        global?:     global?] do

      open = deep? && "<!" || "<"
      close = deep? && "!>" || ">"
      ending = global? && "/g" || ""

      open <> Enum.join(constraints, ",") <> close <> ending
    end
  end

  @doc """
  Make any code fragment safe for being used as part of a matching expression.
  Especially useful when an elixir code fragment evalutes to a string.

  The following code sample yields an invalid expression ...

      iex> import Exjpet.Expression
      Exjpet.Expression
      iex> a = "foo"
      "foo"
      iex> expr = list [a]
      "[foo]"
      iex> try do
      ...>   Exjpet.compile(expr)
      ...> rescue
      ...>   _e -> :invalid_expression
      ...> end
      :invalid_expression

  ... whereas using `safe/1` produces the expected expression.
      iex> import Exjpet.Expression
      Exjpet.Expression
      iex> a = "foo"
      "foo"
      iex> expr = list [safe(a)]
      "[\\\"foo\\\"]"
      iex> epm = Exjpet.compile(expr)
      iex> Exjpet.run(["foo"], epm)
      {true, %{}}
  """
  defmacro safe(frag) do
    quote do
      "#{inspect unquote(frag)}"
    end
  end

  defp default_modifiers, do: [deep: false, global: false]

  defp transform({:with_key, frag}) do
    quote do
      unquote(transform(frag)) <> ":_"
    end
  end

  defp transform({:with, [key: fragk]}) do
    transform({:with_key, fragk})
  end

  defp transform({:with, [value: fragv]}) do
    transform({:with_value, fragv})
  end

  defp transform({:with, [key: fragk, value: fragv]}) do
    quote do
      unquote(transform(fragk)) <> ":" <> unquote(transform(fragv))
    end
  end

  defp transform({:with, [value: fragv, key: fragk]}) do
    transform({:with, [key: fragk, value: fragv]})
  end

  defp transform({:with_value, frag}) do
    quote do
      "_:" <> unquote(transform(frag))
    end
  end

  defp transform(:any) do
    "_"
  end

  defp transform(:some) do
    "*"
  end

  defp transform(:true) do
    "true"
  end

  defp transform(:false) do
    "false"
  end

  defp transform(:null) do
    "null"
  end

  defp transform(frag) when is_number(frag) or is_binary(frag) do
    Macro.to_string(frag)
  end

  defp transform(frag) do
    frag
  end
end
