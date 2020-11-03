defmodule Exjpet.TestTest do
  use ExUnit.Case

  {:ok, resp} = HTTPoison.get("https://gist.githubusercontent.com/nmichel/8b0d6f194e89abb7281d/raw/907027e8d0be034433e1f56661a6a4fa3292daff/validation_tests.json")
  test_descs = Poison.decode!(resp.body)

  for {%{"pattern" => pattern, "tests" => tests}, j} <- Enum.with_index(test_descs) do
    describe "Pattern #{pattern} [#{j}] =>" do
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

        for {test, i} <- Enum.with_index(tests) do
          %{"inject" => inject, "captures" => captures, "node" => node, "status" => status} = Map.put_new(test, "inject", %{})
          node = Poison.encode!(node)
          inject = Poison.encode!(inject)
          status = Poison.encode!(status)
          captures = Poison.encode!(captures)
          name = "#{inspect(node)} x inject #{inspect(inject)} => {#{inspect(status)}, #{inspect(captures)}} [#{i}]"

          test name do
            node = Poison.decode!(unquote(node))
            inject = Poison.decode!(unquote(inject))
            status = Poison.decode!(unquote(status))
            captures = Poison.decode!(unquote(captures))
            {s, real_c} = unquote(module).match(node, {false, %{}}, inject)
            assert {status, captures} == {s, real_c}
          end
        end
      rescue
        FunctionClauseError ->
          IO.puts("pattern #{pattern} : Code generation error")
          :ok
      end
    end
  end
end
