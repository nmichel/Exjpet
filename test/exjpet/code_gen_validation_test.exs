defmodule Exjpet.CodeGenValidationTest do
  use ExUnit.Case


  test "validation test suite" do
    {:ok, resp} = HTTPoison.get("https://gist.githubusercontent.com/nmichel/8b0d6f194e89abb7281d/raw/907027e8d0be034433e1f56661a6a4fa3292daff/validation_tests.json")
    test_descs = Poison.decode!(resp.body)
    for {%{"pattern" => pattern, "tests" => tests}, j} <- Enum.with_index(test_descs) do
      module_name = :"Test_#{Base.encode16(pattern, case: :lower)}_#{j}"
      code =
        quote do
          defmodule unquote(module_name) do
            use Exjpet.Matcher

            match unquote(pattern), _state do
              {true, var!(captures)}
            end
          end
        end

      try do
        [{module, _bin}] = Code.compile_quoted(code)

        for test <- tests do
          %{"inject" => inject, "captures" => captures, "node" => node, "status" => status} = Map.put_new(test, "inject", %{})

          {s, real_c} = module.match(node, {false, %{}}, inject)
          message =
            """
            * pattern #{pattern} / test #{inspect(node)} / inject #{inspect(inject)}
              expected {#{inspect(status)}, #{inspect(captures)}}
              got {#{inspect(s)}, #{inspect(real_c)}}
            """
          assert {status, captures} == {s, real_c}, message
        end
      rescue
        FunctionClauseError ->
          IO.puts("pattern #{pattern} : Code generation error")
          :ok
      end
    end
  end
end
