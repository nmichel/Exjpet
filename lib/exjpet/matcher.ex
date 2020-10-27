defmodule Exjpet.Matcher do
  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)

      @opts unquote(opts)
      Module.register_attribute(__MODULE__, :matchers, accumulate: true)

      @before_compile Exjpet.Matcher.CodeGen
    end
  end

  defmacro match(pattern, body) do
    svar = Macro.var(:_, nil)
    quote do
      match(unquote(pattern), unquote(svar), unquote(body))
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
