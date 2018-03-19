defmodule Exjpet.ValidationTest do
  use ExUnit.Case

  describe "validation test suite" do
    test "with :poison / Poison" do
      do_test_suite(:poison)
    end

    test "with :jason / Jason" do
      do_test_suite(:jason)
    end
  end

  defp do_test_suite(codec) do
    {:ok, resp} = HTTPoison.get("https://gist.githubusercontent.com/nmichel/8b0d6f194e89abb7281d/raw/907027e8d0be034433e1f56661a6a4fa3292daff/validation_tests.json")
    test_descs = codec.decode(resp.body)

    for %{"pattern" => pattern, "tests" => tests} <- test_descs do
      matcher = :ejpet.compile(pattern, codec)
      Enum.each(tests, &do_test(pattern, matcher, Map.put_new(&1, "inject", %{})))
    end
  end

  defp do_test(pattern, matcher, %{"inject" => inject, "captures" => captures, "node" => node, "status" => status}) do
    node_text = :poison.encode(node)
    node_backend = :ejpet.decode(node_text, :ejpet.backend(matcher))
    {s, caps} = :ejpet.run(node_backend, matcher, inject)
    real_c = :ejpet.decode(:ejpet.encode(caps, :ejpet.backend(matcher)), :ejpet.backend(matcher))
    reencoded_exp_c = :ejpet.decode(:ejpet.encode(captures, :poison), :ejpet.backend(matcher))
    message = """
    * pattern #{pattern} / test #{node_text}
      expected {#{inspect status}, #{inspect reencoded_exp_c}}
      got {#{inspect s}, #{inspect real_c}}
    """
    assert {s, real_c} == {status, reencoded_exp_c}, message
  end
end
