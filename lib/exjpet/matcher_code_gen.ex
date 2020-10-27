defmodule Exjpet.Matcher.CodeGen do
  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :opts)

    matchers =
      Module.get_attribute(env.module, :matchers)
      |> Enum.group_by(fn({pattern, state, _body}) -> {pattern, Macro.to_string(state)} end)
      |> Enum.map(fn({{pattern, _state_str}, matchers}) -> {pattern, Enum.map(matchers, &({elem(&1, 1), elem(&1, 2)}))} end)

    matcher_clauses =
      for {pattern, [{state, body}]} <- matchers do
        capture_vars = pattern |> extract_capture_names() |> build_bindings()
        quote do
          def on_match(unquote("#{pattern}"), unquote(state), var!(jnode), var!(captures)) do
            _ = var!(jnode)
            _ = var!(captures)
            unquote_splicing(capture_vars)
            unquote(body)
          end
        end
      end

    patterns =
      Module.get_attribute(env.module, :matchers)
      |> Enum.map(fn({pattern, _state, _body}) -> pattern end)
      |> Enum.uniq()

    Application.ensure_started(:ejpet)

    cache_fun = :ejpet_default_cache.build_cache_fun(:ejpet_default_cache_srv)
    pattern_matcher_fun_mapping =
      for pattern <- patterns do
        if opts[:debug] do
          IO.puts("* Generating matcher for pattern #{pattern}")
        end
        options = opts[:options] || []
        {:ejpet, :code_gen, {_quoted_inner_fun, key}} = :ejpet.compile(pattern, :code_gen, options, cache_fun)
        {pattern, :ejpet_code_gen_generators.build_function_name(key)}
      end

    quoted_funs =
      for {key, quoted_fun} <- cache_fun.({:get_all}) do
        name = :ejpet_code_gen_generators.build_function_name(key)
        if opts[:debug] do
          IO.puts("* Generating submatcher function for #{name}")
        end
        generate_matcher_fun(name, quoted_fun)
      end

    static_matchings =
      if not opts[:reduce] do
        for {pattern, fun_name} <- pattern_matcher_fun_mapping do
          quote do
            if unquote(opts)[:debug] do
              IO.puts("Testing node on matcher function #{unquote(fun_name)}")
            end
            case unquote(fun_name)(node, []) do
              {true, captures} ->
                on_match(unquote(pattern), state, node, captures)
              _ -> :no_match
            end
          end
        end
      else
        [
          quote do
            Enum.reduce(unquote(pattern_matcher_fun_mapping), [], fn({pattern, fun_name}, acc) ->
              res =
                case apply(__MODULE__, fun_name, [node, []]) do
                  {true, captures} ->
                    on_match(pattern, state, node, captures)
                  _ -> :no_match
                end
              [res | acc]
            end)
            |> Enum.reverse()
          end
        ]
      end

    quote location: :keep do
      unquote_splicing(quoted_funs)

      def match(node, state) do
        unquote_splicing(static_matchings)
      end

      def match_dyn(node, state) do
        cache_fun = :ejpet_default_cache.build_cache_fun(:ejpet_default_cache_srv)

        for pattern <- unquote(patterns) do
          epm = :ejpet.compile(pattern, :jsone, [], cache_fun)
          # node = :ejpet.backend(epm).decode(node)
          case :ejpet.run(node, epm) do
            {true, captures} ->
              on_match(pattern, state, node, captures) # (1) Hard reference to a on_match/4 function
            _ ->
              :no_match
          end
        end
      end

      # May or may NOT generate on_match/4 function clauses (if the macro match is not used at all)
      unquote_splicing(matcher_clauses)

      # Therefore we must provide a default implementation of on_match/4 for (1) to compile
      # even if it will NEVER be called
      def on_match(_, _, _, _), do: :not_used_only_for_compilation
    end
  end

  defp generate_matcher_fun(name, body) do
    quote do
      def unquote(name)(node, opts) do
        inner_fun = unquote(body)
        inner_fun.(node, opts)
      end
    end
  end

  @spec extract_capture_names(String.t()) :: [String.t()]
  defp extract_capture_names(expr) do
    Regex.compile("\\(\\?<([A-Za-z0-9_]+)>")
    |> elem(1)
    |> Regex.scan(expr, [capture: :all_but_first])
    |> List.flatten
  end

  @spec build_bindings([String.t()]) :: Macro.output()
  defp build_bindings(var_names) do
    Enum.map(var_names, fn(var_name) ->
      var = String.to_atom(var_name)
      var_ast = Macro.var(var, nil)
      quote do
        cap = var!(captures)
        value = Map.get(cap, unquote(var_name))
        unquote(var_ast) = value
      end
    end)
  end
end
