defmodule :ejpet_code_gen_generators do

  # ---- Capture

  def generate_matcher({:capture, expr, name}, options, cb) do
    {_, key} = expr
    _ = cb.(expr, options, cb)
    matcher = build_function_name(key)

    quote do
      fn(json, params) ->
        case unquote(matcher)(json, params) do
          {true, captures} ->
            {true, :ejpet_code_gen_generators.add_captures(captures, unquote(name), [json])};
          r ->
            r
        end
      end
    end
  end

  # ---- Injection

  def generate_matcher({:inject, type, name}, options, cb) when is_list(name) do
    generate_matcher({:inject, type, :erlang.list_to_binary(name)}, options, cb)
  end

  def generate_matcher({:inject, :boolean, name}, _options, _cb) do
    quote do
      empty = unquote(Macro.escape(empty()))
      fn(what, params) when what == true or what == false ->
        case :ejpet_helpers.get_value(unquote(name), params) do
          what ->
            {true, empty}
          _ ->
            {false, empty}
        end
        (_, _params) ->
          {false, empty}
      end
    end
  end

  def generate_matcher({:inject, :string, name}, _options, _cb) do
    quote do
      empty = unquote(Macro.escape(empty()))
      fn(what, params) when is_binary(what) ->
        case :ejpet_helpers.get_value(unquote(name), params) do
          what ->
            {true, empty}
          _ ->
            {false, empty}
        end
        (_, _params) ->
          {false, empty}
      end
    end
  end

  def generate_matcher({:inject, :number, name}, options, _cb) do
    quote do
      empty = unquote(Macro.escape(empty()))
      options = unquote(Macro.escape(options))
      fn(what, params) when is_number(what) ->
        case :ejpet_helpers.get_value(unquote(name), params) do
          :undefined ->
            {false, empty}
          number ->
            case :ejpet_helpers.get_value(:number_strict_match, options) do
              true ->
                case what === number do
                  true ->
                    {true, empty}
                  _ ->
                  {false, empty}
                end
              _ ->
                case what == number do
                  true ->
                    {true, empty}
                  _ ->
                    {false, empty}
                end
            end
        end
        (_, _params) ->
          {false, empty}
      end
    end
  end

  def generate_matcher({:inject, :regex, name}, _pptions, _cb) do
    quote do
      empty = unquote(Macro.escape(empty()))
      fn(what, params) when is_binary(what) ->
        case :ejpet_helpers.get_value(unquote(name), params) do
          :undefined ->
            {false, empty}
          mp ->
            try do
              case :re.run(what, mp) do
                {:match, _} ->
                    {true, empty}
                _ ->
                    {false, empty}
                end
            catch
                _, _ ->
                    {false, empty}
            end
        end
        (_, _params) ->
          {false, empty}
      end
    end
  end

  # ----- List

  def generate_matcher({:list, :empty}, _options, _cb) do
    quote bind_quoted: [empty: Macro.escape(empty())] do
      fn([], _params) ->
          {true, empty};
        (_, _params) ->
          {false, empty}
      end
    end
  end

  def generate_matcher({:list, :any}, _Options, _CB) do
    quote bind_quoted: [empty: Macro.escape(empty())] do
      fn([], _params) ->
          {true, empty}
        ([{}], _params) -> # jsx special form for empty object
          {false, empty}
        ([{_, _} |_], _params) -> # jsx form for non empty object
          {false, empty}
        ([_|_], _params) ->
          {true, empty}
        (_, _params) ->
          {false, empty}
      end
    end
  end

  def generate_matcher({:list, conditions}, options, cb) do
    matcher_names =
      Enum.map(conditions, fn(expr = {_, key}) ->
        _ = cb.(expr, options, cb)
        build_function_name(key)
      end)

    quote bind_quoted: [empty: Macro.escape(empty()), matcher_names: matcher_names] do
      fn([{}], _params) -> # jsx special form for empty object
          {false, empty}
        ([{_, _} | _], _params) -> # jsx special form for non empty object
          {false, empty}
        ([], _params) -> # cannot match anything in an empty list
          {false, empty}
        (items, params) when is_list(items) ->
          {statuses, _tail} =
            Enum.reduce(matcher_names, {[], items}, fn(matcher, {acc, item_list}) ->
              {s, r} = apply(__MODULE__, matcher, [item_list, params])
              {[s | acc], r}
            end)
          res = {final_status, _acc_captures} =
            Enum.reduce(Enum.reverse(statuses), {true, empty}, fn({s, captures}, {stat, acc}) ->
              {s and stat, :ejpet_code_gen_generators.melt_captures(acc, captures)}
            end)
          case final_status do
            true ->
                res
            false ->
                {false, empty}
          end
        (_, _params) ->
          {false, empty}
      end
    end
  end

  def generate_matcher({:span, exprs}, options, cb) do
    generate_matcher({:span, exprs, false}, options, cb)
  end

  def generate_matcher({:span, exprs, :eol}, options, cb) do
    generate_matcher({:span, exprs, true}, options, cb)
  end

  def generate_matcher({:span, exprs, strict}, options, cb) do
    matchers =
      Enum.map(exprs, fn(expr = {_, key}) ->
        _ = cb.(expr, options, cb)
        build_function_name(key)
      end)

    quote bind_quoted: [matchers: matchers, strict: strict] do
      fn(span, params) when is_list(span) ->
        :ejpet_code_gen_generators.check_span_match(span, __MODULE__, matchers, params, [], strict)
      end
    end
  end

  def generate_matcher({:find, expr}, options, cb) do
    {_, key} = expr
    _ = cb.(expr, options, cb)
    span_matcher = build_function_name(key)

    quote do
      fn(span, params) ->
        continue_until_span_match(span, __MODULE__, unquote(span_matcher), params)
      end
    end
  end

  # ----- Unit

  def generate_matcher({:string, bin_string}, _options, _cb) do
    quote do
      empty = unquote(Macro.escape(empty()))
      fn(what, _params) ->
        case what do
          unquote(bin_string) ->
            {true, empty}
          _ ->
            {false, empty}
        end
      end
    end
  end

  def generate_matcher({:regex, bin_string}, options, _cb) do
    quote bind_quoted: [empty: Macro.escape(empty()), bin_string: bin_string, options: options] do
      # WARNING : this is expensive ! As we cannot rely on any cache mechanism, the regex must
      # recompile each time the generated matching function is called.
      # One solution would be to propose an option to __using__, allowing to add a cache table
      # to the current (i.e. the process running the function) process directory ...

      # TBD : :re.compile crashes when passed unknown options
      # re_options = filter_re_options(options)
      # {:ok, mp} = :re.compile(bin_string, re_options)
      {:ok, mp} = :re.compile(bin_string, [])
      fn
        (what, _params) when is_binary(what) ->
          try do
            case :re.run(what, mp) do
              {:match, _} ->
                {true, empty}
              _ ->
                {false, empty}
              end
          catch
            _, _ ->
              {false, empty}
          end
        (_, _params) ->
          {false, empty}
      end
    end
  end

  def generate_matcher({:number, number}, options, _cb) do
    case :ejpet_helpers.get_value(:number_strict_match, options) do
      true ->
        quote do
          empty = unquote(Macro.escape(empty()))
          fn
            (unquote(number), _params) ->
              {true, empty}
            (_, _params) ->
              {false, empty}
          end
        end
      _ ->
        quote do
          empty = unquote(Macro.escape(empty()))
          fn
            (what, _params) when is_number(what) ->
              case what == unquote(number) do
                true ->
                  {true, empty}
                _ ->
                  {false, empty}
              end
            (_, _params) ->
              {false, empty}
          end
        end
    end
  end

  def generate_matcher(:any, _options, _cb) do
    quote bind_quoted: [empty: Macro.escape(empty())] do
      fn(_, _params) ->
        {true, empty}
      end
    end
  end

  def generate_matcher(what, _options, _cb) when what in [true, false, :null] do
    quote location: :keep do
      empty = unquote(Macro.escape(empty()))
      fn(item, _params) ->
        case item do
          nil when unquote(what) == :null ->
            {true, empty}
          unquote(what) ->
            {true, empty}
          _ ->
            {false, empty}
        end
      end
    end
  end

  # -----

  def check_span_match([], _module, [_|_], _params, _acc, _strict) do
    {{false, empty()}, []}
  end

  def check_span_match([_|_], _module, [], _params, _acc, true) do
    {{false, empty()}, []}
  end

  def check_span_match(what, _module, [], _params, acc, _strict) do
    captures =
      Enum.reduce(Enum.reverse(acc), empty(), fn(cap, cap_acc) ->
        melt_captures(cap_acc, cap)
      end)
    {{true, captures}, what}
  end

  def check_span_match([e | rest], module, [matcher | tail], params, acc, strict) do
    stat = apply(module, matcher, [e, params])
    case stat do
      {false, _} ->
        {stat, rest}
      {true, cap} ->
        check_span_match(rest, module, tail, params, [cap | acc], strict)
    end
  end

  def empty(), do: %{}

  def melt_captures(empty, c) when map_size(empty) == 0 do
    c
  end
  def melt_captures(c, empty) when map_size(empty) == 0 do
    c
  end
  def melt_captures(p1, p2) do
    :ejpet_helpers.melt(p1, p2)
  end

  def add_captures(empty, name, values) when map_size(empty) == 0 do
    Map.put(%{}, name, values)
  end

  def add_captures(pairs, name, values) do
    new = Map.put(%{}, name, values)
    :ejpet_helpers.melt(new, pairs)
  end

  def build_function_name(key) do
    :"matcher_#{Base.encode16(key, case: :lower)}"
  end
end