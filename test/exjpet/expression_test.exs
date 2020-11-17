defmodule Exjpet.ExpressionTest do
  use ExUnit.Case
  import Exjpet.Expression

  doctest Exjpet.Expression

  test "list expressions" do
    assert list() == "[]"
    assert list([]) == "[]"
    assert list([1]) == "[1]"
    assert list([1, 42]) == "[1,42]"
    assert list([1, "foo"]) == "[1,\"foo\"]"
    assert list([:any, "foo", :some]) == "[_,\"foo\",*]"
  end

  test "object expressions" do
    assert object() == "{}"
    assert object([]) == "{}"
    assert object(with_key: "foo") == "{\"foo\":_}"
    assert object(with_value: 42) == "{_:42}"
    assert object(with_value: "foo") == "{_:\"foo\"}"
    assert object(with: [key: "foo", value: "bar"]) == "{\"foo\":\"bar\"}"
  end

  test "capture expressions" do
    assert capture(:any, as: :val) == "(?<val>_)"
    assert capture(:any, as: "val") == "(?<val>_)"
  end

  test "set expressions" do
    assert set() == "<>"
    assert set([]) == "<>"
    assert set([], [global: true]) == "<>/g"
    assert set([], [deep: true]) == "<!!>"
    assert set([], [deep: true, global: true]) == "<!!>/g"
    assert set([set([], [deep: true])], [global: true]) == "<<!!>>/g"
  end

  @capname "val"
  test "simple compile-time expressions" do
    assert capture(:any, as: @capname) == "(?<val>_)"

    defmodule Config do
      def num_param do
        42
      end
      def expr(p) do
        list [:any, object(with_key: safe(p))]
      end
    end

    assert capture(Config.expr("foo"), as: @capname) == "(?<val>[_,{\"foo\":_}])"
    assert list([to_string(Config.num_param)]) == "[42]"
  end

  test "simple runtime expressions" do
    get_name =
      fn name ->
        name
      end
    builder =
      fn name ->
        object(with_key: safe(get_name.(name)))
        |> capture(as: get_name.(name))
      end

    assert builder.("foo") == "(?<foo>{\"foo\":_})"
  end

  test "advanced compile-time expressions" do
    defmodule MyMacro do
      defmacro match(name, what) do
        quote bind_quoted: [name: name, what: what] do
          def unquote(name)() do
            unquote(what)
          end
        end
      end
    end

    defmodule Foo do
      import Exjpet.Expression
      import MyMacro

      [{:foo, object([with_key: "foo"])}, {:bar, list(["bar"])}]
      |> Enum.each(fn({name, pattern}) -> match(name, pattern) end)
    end

    assert Foo.foo() == "{\"foo\":_}"
    assert Foo.bar() == "[\"bar\"]"
  end
end
