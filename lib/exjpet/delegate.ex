defmodule Exjpet.Delegate do
  defmacro __using__(module) do
    specs =
      module.module_info[:exports]
      |> Kernel.--([{:module_info, 0}, {:module_info, 1}])

    asts =
      specs |> Enum.map(&build_signature(&1, __CALLER__.module))

    quote do
      unquote_splicing(asts)
    end
  end

  def build_signature({name, count}, mod) do
    quote do
      defdelegate unquote(name)(unquote_splicing(Macro.generate_arguments(count, mod))), to: :ejpet
    end
  end
end
