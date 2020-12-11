defmodule Exjpet.Matcher do
  @moduledoc """
  Use `Matcher` to define module that acts as JSON nodes matcher.

  Under the hood matching functions are build using [ejpet](https://hex.pm/packages/ejpet) at compile-time.

  A matcher module has a `match/2` (default name, can be overriden via `match_function_name` parameter when `using`) function automatically
  injected which takes a json  node (in `Poison` layout) and an unspecified `state`. That function processes the body
  of each clause the json node matches.

  ## Example

      iex> defmodule MyMatcher do
      ...>   use Exjpet.Matcher
      ...>
      ...>   match ~s("nomatch"), _state do
      ...>     :error
      ...>   end
      ...>
      ...>   match ~s({#"foo": _}), state do
      ...>     state |> Map.put(:found_foo, true)
      ...>   end
      ...>
      ...>   match ~s({_: 42}), state do
      ...>     state |> Map.put(:found_42, true)
      ...>   end
      ...>
      ...>   match ~s(_), state do
      ...>     state |> Map.put(:found_any, true)
      ...>   end
      ...> end
      ...>
      ...> state = %{}
      ...> Poison.decode!(~s({"foobar": 42})) |> MyMatcher.match(state)
      %{found_foo: true, found_42: true, found_any: true}

  ## Matching rules

  * You do not talk about Match Club,
  * Match clauses are processed in declaration order,
  * For each node, only matching clauses are processed,
  * The `state` is passed from matching clause to matching clause, each one amending (or not) and returning it. Stated otherwise
    the final state is the result of a reduction over the matching clauses (non matching clauses are ignored).


  Declaring multiple clauses for the same pattern is suported, allowing for matching on the second parameter.

  ## Example

      iex> defmodule MySecondMatcher do
      ...>   use Exjpet.Matcher
      ...>
      ...>   match ~s({#"foo": _}), %{status: :idle} = state do
      ...>     %{state | status: :ping_foo, foo_count: state.foo_count + 1}
      ...>   end
      ...>
      ...>   match ~s({#"foo": _}), %{status: :ping_foo} = state do
      ...>     %{state | status: :pong_foo, foo_count: state.foo_count + 1}
      ...>   end
      ...>
      ...>   match ~s({#"foo": _}), %{status: :pong_foo} = state do
      ...>     %{state | status: :ping_foo, foo_count: state.foo_count + 1}
      ...>   end
      ...>
      ...>   match ~s({_: 42}), state do
      ...>     %{state | foo_42_count: state.foo_42_count + 1}
      ...>   end
      ...>
      ...>   match ~s(_), state do
      ...>     %{state | node_count: state.node_count + 1}
      ...>   end
      ...>
      ...>   def new(), do: %{status: :idle, foo_count: 0, foo_42_count: 0, node_count: 0}
      ...> end
      ...>
      ...> state = MySecondMatcher.new()
      ...> state = Poison.decode!(~s({"foobar": 42})) |> MySecondMatcher.match(state)
      %{foo_42_count: 1, foo_count: 1, node_count: 1, status: :ping_foo}
      ...> state = Poison.decode!(~s(["ranavoar"])) |> MySecondMatcher.match(state)
      %{foo_42_count: 2, foo_count: 2, node_count: 3, status: :pong_foo}
      ...> Poison.decode!(~s({"foobar": 42})) |> MySecondMatcher.match(state)
      %{foo_42_count: 2, foo_count: 2, node_count: 3, status: :pong_foo}
  """

  defmacro __using__(opts) do
    quote do
      import unquote(__MODULE__)

      @opts unquote(opts)
      Module.register_attribute(__MODULE__, :matchers, accumulate: true)

      @before_compile Exjpet.Matcher.CodeGen
      @after_compile Exjpet.Matcher.CodeGen
    end
  end

  @doc """
  Declares a matching clause.

  When the body is executed, some bindings are automatically provided :
  - `jnode` is bound to the processed json node,
  - `captures` is bound to the map of all captures gathered during json node processing,
  - each named capture declared in the pattern yield to a binding.

  ## Example

      iex> defmodule MyMatcher do
      ...>   use Exjpet.Matcher
      ...>
      ...>   match ~s("nomatch"), _state do
      ...>     :error
      ...>   end
      ...>
      ...>   match ~s[{#"foo": (?<value>_)}], state do
      ...>     state
      ...>     |> Map.put(:node, jnode)
      ...>     |> Map.put(:captures, captures)
      ...>     |> Map.put(:value, value)
      ...>   end
      ...> end
      ...>
      ...> state = %{fooNode: nil}
      ...> Poison.decode!(~s({"foobar": 42})) |> MyMatcher.match(state)
      %{fooNode: nil, captures: %{"value" => '*'}, node: %{"foobar" => 42}, value: '*'}
  """
  defmacro match(pattern, state, do: code) do
    quote bind_quoted: [pattern: pattern,
                        state: Macro.escape(state),
                        body: Macro.escape(code)]
    do
      @matchers {pattern, state, body}
    end
  end
end
