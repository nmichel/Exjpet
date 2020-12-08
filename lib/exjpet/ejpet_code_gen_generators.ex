defmodule :ejpet_code_gen_generators do
  @moduledoc """
  This module is a backend module for `ejpet` wich produces AST of matching functions.
  """

  # ---- Capture

  def generate_matcher({:capture, expr, name}, options, cb) do
    {_, key} = expr
    _ = cb.(expr, options, cb)
    matcher = build_function_name(key)

    quote do
      fn(json, params) ->
        case unquote(matcher)(json, params) do
          {true, captures} ->
            {true, :ejpet_code_gen_generators.add_captures(captures, unquote(name), [json])}
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
    empty = Macro.escape(empty())
    quote do
      fn(what, params) when what == true or what == false ->
        case :ejpet_helpers.get_value(unquote(name), params) do
          ^what ->
            {true, unquote(empty)}
          _ ->
            {false, unquote(empty)}
        end
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:inject, :string, name}, _options, _cb) do
    quote do
      empty = unquote(Macro.escape(empty()))
      fn(what, params) when is_binary(what) ->
        case :ejpet_helpers.get_value(unquote(name), params) do
          ^what ->
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

  # ---- Object

  def generate_matcher({:object, :any}, _options, _cb) do
    empty = Macro.escape(empty())
    quote do
      fn(%{}, _params) ->
          {true, unquote(empty)}
        ([{}], _params) ->
          {true, unquote(empty)}
        ([{_, _} | _], _params) ->
          {true, unquote(empty)}
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:object, conditions}, options, cb) do
    pair_matcher_names =
      Enum.map(conditions, fn({_, key} = expr) ->
        _ = cb.(expr, options, cb)
        build_function_name(key)
      end)

    empty = Macro.escape(empty())

    quote do
      fn(m = %{}, params) ->
          :ejpet_code_gen_generators.do_match_object(Map.to_list(m), params, __MODULE__, unquote(pair_matcher_names))
        (items, params) when is_list(items) ->
          :ejpet_code_gen_generators.do_match_object(items, params, __MODULE__, unquote(pair_matcher_names))
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:pair, :any, val_matcher_desc}, options, cb) do
    {_, key} = val_matcher_desc
    _ = cb.(val_matcher_desc, options, cb)
    val_matcher_name = build_function_name(key)

    empty = Macro.escape(empty())

    quote do
      fn({_key, val}, params) ->
          unquote(val_matcher_name)(val, params)
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:pair, key_matcher_desc, :any}, options, cb) do
    {_, key} = key_matcher_desc
    _ = cb.(key_matcher_desc, options, cb)
    key_matcher_name = build_function_name(key)

    empty = Macro.escape(empty())

    quote do
      fn({key, _val}, params) ->
          unquote(key_matcher_name)(key, params)
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:pair, key_matcher_desc, val_matcher_desc}, options, cb) do
    {_, key_matcher_key} = key_matcher_desc
    _ = cb.(key_matcher_desc, options, cb)
    key_matcher_name = build_function_name(key_matcher_key)

    {_, val_matcher_key} = val_matcher_desc
    _ = cb.(val_matcher_desc, options, cb)
    val_matcher_name = build_function_name(val_matcher_key)

    empty = Macro.escape(empty())

    quote do
      fn({key, val}, params) ->
          {s1, cap1} = unquote(key_matcher_name)(key, params)
          {s2, cap2} = unquote(val_matcher_name)(val, params)
          case s1 and s2 do
            true ->
              {true, unquote(__MODULE__).melt_captures(cap1, cap2)}
            _ ->
              {false, unquote(empty)}
          end
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  # ----- List

  def generate_matcher({:list, :empty}, _options, _cb) do
    empty = Macro.escape(empty())
    quote do
      fn([], _params) ->
          {true, unquote(empty)}
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:list, :any}, _options, _cb) do
    empty = Macro.escape(empty())
    quote do
      fn([], _params) ->
          {true, unquote(empty)}
        ([{}], _params) -> # jsx special form for empty object
          {false, unquote(empty)}
        ([{_, _} |_], _params) -> # jsx form for non empty object
          {false, unquote(empty)}
        ([_|_], _params) ->
          {true, unquote(empty)}
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:list, conditions}, options, cb) do
    matcher_names =
      Enum.map(conditions, fn({_, key} = expr) ->
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
      Enum.map(exprs, fn({_, key} = expr) ->
        _ = cb.(expr, options, cb)
        build_function_name(key)
      end)

    quote do
      fn(span, params) when is_list(span) ->
        :ejpet_code_gen_generators.check_span_match(span, __MODULE__, unquote(matchers), params, [], unquote(strict))
      end
    end
  end

  def generate_matcher({:find, expr}, options, cb) do
    {_, key} = expr
    _ = cb.(expr, options, cb)
    span_matcher_name = build_function_name(key)

    quote do
      fn(span, params) ->
        unquote(__MODULE__).continue_until_span_match(span, __MODULE__, unquote(span_matcher_name), params)
      end
    end
  end

  # ----- Iterable

  def generate_matcher({:iterable, :any}, _options, _cb) do
    empty = Macro.escape(empty())
    quote do
      # jsone represents both list and object as erlang lists.
      # Therefore, checking if an item is an erlang list is enough to say
      # that it is an iterable.
      #
      fn(what, _params) when is_list(what) ->
          {true, unquote(empty)}
        (%{} = what, _params) ->
          {true, unquote(empty)}
        (what, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher({:iterable, conditions, flags}, options, cb) do
    matcher_names =
      Enum.map(conditions, fn({_, key} = expr) ->
        _ = cb.(expr, options, cb)
        build_function_name(key)
      end)

    empty = Macro.escape(empty())

    quote do
      fn(%{} = m, params) ->
          unquote(__MODULE__).do_match_iterable(Map.to_list(m), params, __MODULE__, unquote(matcher_names), unquote(flags))
        (items, params) when is_list(items) ->
          unquote(__MODULE__).do_match_iterable(items, params, __MODULE__, unquote(matcher_names), unquote(flags))
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  # ----- Descendant

  def generate_matcher({:descendant, conditions, flags}, options, cb) do
    matcher_names =
      Enum.map(conditions, fn({_, key} = expr) ->
        _ = cb.(expr, options, cb)
        build_function_name(key)
      end)

    empty = Macro.escape(empty())

    quote do
      fn(%{} = m, params) ->
            unquote(__MODULE__).do_match_descendant(Map.to_list(m), params, __MODULE__, unquote(matcher_names), unquote(flags))
          (items, params) when is_list(items) ->
            unquote(__MODULE__).do_match_descendant(items, params, __MODULE__, unquote(matcher_names), unquote(flags))
          (_, _params) ->
            {false, unquote(empty)}
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

  def generate_matcher(what, _options, _cb) when what in [true, false] do
    empty = Macro.escape(empty())
    quote location: :keep do
      fn(unquote(what), _params) ->
          {true, unquote(empty)}
        (_, _params) ->
          {false, unquote(empty)}
      end
    end
  end

  def generate_matcher(:null, _options, _cb) do
    empty = Macro.escape(empty())
    quote location: :keep do
      fn(nil, _params) ->
          {true, unquote(empty)}
        (_, _params) ->
          {false, unquote(empty)}
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

  def continue_until_span_match([], _module, _span_matcher, _params) do
    {{false, empty()}, []}
  end

  def continue_until_span_match([_ | tail] = what, module, span_matcher, params) do
    stat = apply(module, span_matcher, [what, params])
    case stat do
      {{true, _}, _} = r ->
        r
      _ ->
        continue_until_span_match(tail, module, span_matcher, params)
    end
  end

  def continue_until_match([], _module, _matcher, _params) do
    {{false, empty()}, []}
  end

  def continue_until_match([item | tail], module, matcher, params) do
    stat = apply(module, matcher, [item, params])
    case stat do
      {true, _} = r ->
        {r, tail}
      _ ->
        continue_until_match(tail, module, matcher, params)
    end
  end

  def continue_until_value_match([{}], _module, _matcher, _params, _flags) do
    {{false, empty()}, []}
  end

  def continue_until_value_match([], _module, _matcher, _params, _flags) do
    {{false, empty()}, []}
  end

  def continue_until_value_match(iterable, module, matcher, params, true) do
    {continue_until_end_(iterable, module, matcher, params), []}
  end

  def continue_until_value_match([{_key, val} | tail], module, matcher, params, false) do
    stat = apply(module, matcher, [val, params])
    case stat do
      r = {true, _} ->
        {r, tail}
      _ ->
        continue_until_value_match(tail, module, matcher, params, false)
    end
  end

  def continue_until_value_match([item | tail], module, matcher, params, false) do
    stat = apply(module, matcher, [item, params])
    case stat do
      r = {true, _} ->
        {r, tail}
      _ ->
        continue_until_value_match(tail, module, matcher, params, false)
    end
  end

  def continue_until_end_(iterable, module, matcher, params) do
    continue_until_end_(iterable, module, matcher, params, {false, empty()})
  end

  def continue_until_end_([{}], _module, _matcher, _params, acc) do
    acc
  end

  def continue_until_end_([], _module, _matcher, _params, acc) do
    acc
  end

  def continue_until_end_([{_Key, val} | tail], module, matcher, params, {acc_status, acc_captures}) do
    {local_status, local_captures} = apply(module, matcher, [val, params])
    continue_until_end_(tail, module, matcher, params, {local_status or acc_status, melt_captures(acc_captures, local_captures)})
  end

  def continue_until_end_([item | tail], module, matcher, params, {acc_status, acc_captures}) do
    {local_status, local_captures} = apply(module, matcher, [item, params])
    continue_until_end_(tail, module, matcher, params, {local_status or acc_status, melt_captures(acc_captures, local_captures)})
  end

  def deep_continue_until_value_match(m = %{}, _module, _matcher, _params, _flags) when map_size(m) == 0 do
    {{false, empty()}, []}
  end

  def deep_continue_until_value_match([{}], _module, _matcher, _Params, _flags) do
    {{false, empty()}, []}
  end

  def deep_continue_until_value_match([], _module, _matcher, _params, _flags) do
    {{false, empty()}, []}
  end

  def deep_continue_until_value_match(%{} = m, module, matcher, params, flags) do
    deep_continue_until_value_match(Map.to_list(m), module, matcher, params, flags)
  end

  def deep_continue_until_value_match(iterable, module, matcher, params, true) do
    {deep_continue_until_end_(iterable, module, matcher, params), empty()}
  end

  def deep_continue_until_value_match([{_key, val} | tail], module, matcher, params, flags) do
    case apply(module, matcher, [val, params]) do
      {true, _} = r ->
        {r, tail}
      _ ->
        deep_continue_after_non_value_match(val, tail, module, matcher, params, flags)
    end
  end

  def deep_continue_until_value_match([item | tail], module, matcher, params, flags) do
    case apply(module, matcher, [item, params]) do
      {true, _} = r ->
        {r, tail}
      _ ->
        deep_continue_after_non_value_match(item, tail, module, matcher, params, flags)
      end
  end

  defp deep_continue_after_non_value_match(%{} = item, tail, module, matcher, params, flags) when map_size(item) > 0 do
    case deep_continue_until_value_match(item, module, matcher, params, flags) do
      {{true, _} = r2, _} ->
        {r2, tail}
      _ ->
        deep_continue_until_value_match(tail, module, matcher, params, flags)
    end
  end

  defp deep_continue_after_non_value_match([_|_] = item, tail, module, matcher, params, flags) do
    case deep_continue_until_value_match(item, module, matcher, params, flags) do
      {{true, _} = r2, _} ->
        {r2, tail}
      _ ->
        deep_continue_until_value_match(tail, module, matcher, params, flags)
    end
  end

  defp deep_continue_after_non_value_match(_item, tail, module, matcher, params, flags) do
    deep_continue_until_value_match(tail, module, matcher, params, flags)
  end

  def deep_continue_until_end_(iterable, module, matcher, params) do
    deep_continue_until_end_(iterable, module, matcher, params, {false, empty()})
  end

  def deep_continue_until_end_(%{} = m, _module, _matcher, _params, acc) when map_size(m) == 0 do
    acc
  end

  def deep_continue_until_end_([{}], _module, _matcher, _params, acc) do
    acc
  end

  def deep_continue_until_end_([], _module, _matcher, _params, acc) do
    acc
  end

  def deep_continue_until_end_(%{} = m, module, matcher, params, acc) do
    deep_continue_until_end_(Map.to_list(m), module, matcher, params, acc)
  end

  def deep_continue_until_end_([{_key, val} | tail], module, matcher, params, {acc_status, acc_captures}) do
    {local_status, local_captures} = apply(module, matcher, [val, params])
    local_acc = {local_status or acc_status, melt_captures(acc_captures, local_captures)}
    case val do
        %{} = m when map_size(m) >= 0 ->
            r = deep_continue_until_end_(val, module, matcher, params, local_acc)
            deep_continue_until_end_(tail, module, matcher, params, r)
        [_|_] ->
            r = deep_continue_until_end_(val, module, matcher, params, local_acc)
            deep_continue_until_end_(tail, module, matcher, params, r)
        _ ->
            deep_continue_until_end_(tail, module, matcher, params, local_acc)
    end
  end

  def deep_continue_until_end_([item | tail], module, matcher, params, {acc_status, acc_captures}) do
    {local_status, local_captures} = apply(module, matcher, [item, params])
    local_acc = {local_status or acc_status, melt_captures(acc_captures, local_captures)}
    case item do
        %{} ->
            r = deep_continue_until_end_(item, module, matcher, params, local_acc)
            deep_continue_until_end_(tail, module, matcher, params, r)
        [_|_] ->
            r = deep_continue_until_end_(item, module, matcher, params, local_acc)
            deep_continue_until_end_(tail, module, matcher, params, r)
        _ ->
            deep_continue_until_end_(tail, module, matcher, params, local_acc)
    end
  end

  def do_match_object([{_, _} | _] = items, params, module, pair_matcher_names) do
    r = Enum.map(pair_matcher_names, &continue_until_match(items, module, &1, params))
    {acc_captures, acc_failed_count} =
      Enum.reduce(r, {empty(), 0},
        fn({{true, captures}, _}, {cap_acc, failed_acc}) ->
            {melt_captures(cap_acc, captures), failed_acc}
          (_, {cap_acc, failed_acc}) ->
            {cap_acc, failed_acc + 1}
        end)
    case acc_failed_count do
      0 ->
        {true, acc_captures}
      _ ->
        {false, empty()}
    end
  end

  def do_match_object(_, _params, _module, _pair_matcher_names) do
    {false, empty()}
  end

  def do_match_iterable(items, params, module, matcher_names, flags) do
    r = Enum.map(matcher_names, &continue_until_value_match(items, module, &1, params, flags))
    {acc_captures, acc_failed_count} =
      Enum.reduce(r, {empty(), 0},
        fn({{true, captures}, _}, {cap_acc, failed_acc}) ->
            {melt_captures(cap_acc, captures), failed_acc}
          (_, {cap_acc, failed_acc}) ->
            {cap_acc, failed_acc + 1}
      end)
    case acc_failed_count do
      0 ->
        {true, acc_captures}
      _ ->
        {false, empty()}
    end
  end

  def do_match_descendant(items, params, module, matcher_names, flags) when is_list(items) do
    r = Enum.map(matcher_names, &deep_continue_until_value_match(items, module, &1, params, flags))
    {acc_captures, acc_failed_count} =
      Enum.reduce(r, {empty(), 0},
        fn({{true, captures}, _}, {cap_acc, failed_acc}) ->
            {melt_captures(cap_acc, captures), failed_acc}
          (_, {cap_acc, failed_acc}) ->
            {cap_acc, failed_acc + 1}
      end)
    case acc_failed_count do
        0 ->
          {true, acc_captures}
        _ ->
          {false, empty()}
    end
  end

  def do_match_descendant(_, _params, _module, _matcher_names, _flags) do
    {false, empty()}
  end

  def empty, do: %{}

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
