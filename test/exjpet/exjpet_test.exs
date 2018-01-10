defmodule ExjpetTest do
  use ExUnit.Case
  doctest Exjpet

  test "decode with :poison.decode/1" do
    text = "[1, 2, 3]"
    {:ok, json} = Poison.decode(text)
    assert :poison.decode(text) == json
  end

  test "encode with :poison.encode/1" do
    json = [1, 2, 3, %{a: 42}]
    {:ok, text} = Poison.encode(json)
    assert :poison.encode(json) == text
  end

  test "Exjpet.compile/2 and Exjpet.run/2" do
    {:ok, json} =
      "{\"foo\": [false, 2, true, true]}"
      |> Poison.decode()
    epm = Exjpet.compile("<(?<cap>[*, 2, *])>/g", :poison)
    assert {:true, %{"cap" => [[false, 2, true, true]]}} == Exjpet.run(json, epm)

    {:ok, json} =
      "[[1, 2, 3, 4], {\"foo\": [false, 2, true, true]}, [10, 2, 30, 40]]"
      |> Poison.decode()
    epm = Exjpet.compile("<(?<cap>[*, 2, *])>/g", :poison)
    assert {:true, %{"cap" => [[1, 2, 3, 4], [10, 2, 30, 40]]}} == Exjpet.run(json, epm)

    {:ok, json} =
      "[[1, 2, 3, 4], {\"foo\": [false, 2, true, true]}, [10, 2, 30, 40]]"
      |> Poison.decode()
    epm = Exjpet.compile("<!(?<cap>[*, 2, *])!>/g", :poison)
    assert {:true, %{"cap" => [[1, 2, 3, 4], [false, 2, true, true], [10, 2, 30, 40]]}} == Exjpet.run(json, epm)
  end

  test "Exjpet.compile/1 default to :poison" do
    {:ok, json} =
      "{\"foo\": [false, 2, true, true]}"
      |> Poison.decode()
    epm = Exjpet.compile("<(?<cap>[*, 2, *])>/g")
    assert Exjpet.backend(epm) == :poison
  end

  test "get codec with Exjpet.backend/1" do
    epm = Exjpet.compile("<!(?<cap>[*, 2, *])!>/g", :poison)
    assert :poison = Exjpet.backend(epm)
  end

  test "decode with Exjpet.decode/1" do
    epm = Exjpet.compile("<!(?<cap>[*, 2, *])!>/g", :poison)
    json =
      "[[1, 2, 3, 4], {\"foo\": [false, 2, true, true]}, [10, 2, 30, 40]]"
      |> Exjpet.decode(Exjpet.backend(epm))
    assert {:true, %{"cap" => [[1, 2, 3, 4], [false, 2, true, true], [10, 2, 30, 40]]}} == Exjpet.run(json, epm)
  end
end
