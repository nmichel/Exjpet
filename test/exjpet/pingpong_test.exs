defmodule Exjpet.PingPongTest do
  use ExUnit.Case

  defmodule PingPong do
    @moduledoc """
    Node matcher that counts
    - valid transitions between states 'ping' and 'pong',
    - errors,
    - total number of nodes received
    """

    use Exjpet.Matcher

    @ping "ping"
    @pong "pong"
    @initial @ping

    defstruct state: @initial, errors: 0, pings: 0, pongs: 0, msgs: 0

    match ~s("#{@ping}"), %{state: @ping, errors: errors} = state do
      %__MODULE__{state | errors: errors+1}
    end

    match ~s("#{@pong}"), %{state: @ping, pongs: pongs} = state do
      %__MODULE__{state | state: @pong, pongs: pongs+1}
    end

    match ~s("#{@ping}"), %{state: @pong, pings: pings} = state do
      %__MODULE__{state | state: @ping, pings: pings+1}
    end

    match ~s("#{@pong}"), %{state: @pong, errors: errors} = state do
      %__MODULE__{state | errors: errors+1}
    end

    match "_", %{msgs: msgs} = state do
      %__MODULE__{state | msgs: msgs+1}
    end
  end

  test "count all nodes" do
    state = %PingPong{}
    node = Poison.decode!("[true, false]")
    %PingPong{msgs: 1, pings: 0, pongs: 0} = PingPong.match(node, state)
  end

  test "valid ping / pong sequence" do
    state = %PingPong{}
    node_pong = Poison.decode!("\"pong\"")
    node_ping = Poison.decode!("\"ping\"")
    sequence = [node_pong, node_ping, node_pong, node_ping, node_pong, node_ping, node_pong, node_ping, node_pong, node_ping]
    final_state = sequence |> Enum.reduce(state, &PingPong.match(&1, &2))
    sequence_length = length(sequence)
    pongs = div(sequence_length, 2)
    pings = pongs
    assert %PingPong{msgs: length(sequence), pings: pings, pongs: pongs, errors: 0} === final_state
  end

  test "erroneous ping / pong sequence" do
    state = %PingPong{}
    node_pong = Poison.decode!("\"pong\"")
    node_ping = Poison.decode!("\"ping\"")
    node_ignored = Poison.decode!("\"coooot\"")
    sequence = [node_pong, node_ping, node_pong, node_ignored, node_pong, node_ping, node_pong, node_ping, node_pong, node_ping]
    final_state = sequence |> Enum.reduce(state, &PingPong.match(&1, &2))
    pings = 4
    pongs = 4
    errors = 1
    assert %PingPong{msgs: length(sequence), pings: pings, pongs: pongs, errors: errors} === final_state
  end
end
