defmodule Exjpet.Matcher do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)

      @opts unquote(opts)
      Module.register_attribute(__MODULE__, :matchers, accumulate: true)

      @before_compile Exjpet.Matcher.CodeGen
      @after_compile Exjpet.Matcher.CodeGen
    end
  end

  defmacro match(pattern, state, do: code) do
    quote bind_quoted: [pattern: pattern,
                        state: Macro.escape(state),
                        body: Macro.escape(code)]
    do
      @matchers {pattern, state, body}
    end
  end
end
