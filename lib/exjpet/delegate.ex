defmodule Exjpet.Delegate do
  @moduledoc """
  `Exjpet.Delegate` inject functions delegation to the target module, for all
  exported functions of that module.

  ## Example

  The following module proxies Erlang `:maps` module.
  For illustration purpose it also exports a `foo` function.

      iex> defmodule MyMap do
      ...>   use Exjpet.Delegate, to: :maps
      ...>   def foo do
      ...>     :foo
      ...>   end
      ...> end
      iex> MyMap.get(:a, %{a: 42})
      42
      iex> MyMap.to_list(%{a: 42, b: "foo"})
      [a: 42, b: "foo"]
      iex> MyMap.foo
      :foo

  ## Aliasing

  Using alias as target module is not supported.

  Following declaration will compile

      defmodule DelegateToList do
        use Exjpet.Delegate, List # ok
      end

  But that one won't

      defmodule FailedDelegateToList do
        alias List, as: MyList
        use Exjpet.Delegate, MyList # failed !
      end
  """

  @exclusions [{:module_info, 0}, {:module_info, 1}, {:__info__, 1}]

  defmacro __using__(opts \\ [])

  defmacro __using__(opts) do
    module = Keyword.fetch!(opts, :to)
    exclusions = Keyword.get(opts, :except, []) |> Keyword.merge(@exclusions)

    asts =
      module
      |> resolve()
      |> apply(:module_info, [])
      |> Keyword.fetch!(:exports)
      |> Kernel.--(exclusions)
      |> Enum.map(&build_signature(&1, __CALLER__.module, module))

    quote do
      unquote_splicing(asts)
    end
  end

  defp resolve({:__aliases__, _ctxt, names}) do
    names
    |> Enum.join(".")
    |> (&("Elixir."<>&1)).()
    |> to_string()
    |> String.to_atom()
  end
  defp resolve(module) when is_atom(module) do
    module
  end

  defp build_signature({name, count}, mod, target) do
    quote do
      defdelegate unquote(name)(unquote_splicing(Macro.generate_arguments(count, mod))), to: unquote(target)
    end
  end
end
