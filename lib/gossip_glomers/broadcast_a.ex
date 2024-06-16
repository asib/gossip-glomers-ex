defmodule GossipGlomers.BroadcastA do
  use GossipGlomers.Node

  def init_state do
    %{messages: [], node_neighbours: %{}}
  end

  @impl true
  def handle_info(
        {"broadcast", msg, %{"message" => id} = body},
        %{node_id: node_id, node_neighbours: node_neighbours} = state
      ) do
    neighbours =
      case node_neighbours do
        %{^node_id => neighbours} -> neighbours
        _ -> []
      end

    state =
      Enum.reduce(neighbours, state, fn neighbour, state ->
        send_msg(neighbour, body, state)
      end)
      |> then(&reply(msg, %{"type" => "broadcast_ok"}, &1))

    {:noreply, %{state | messages: [id | state.messages]}}
  end

  @impl true
  def handle_info({"read", msg, _body}, %{messages: messages} = state) do
    state =
      reply(
        msg,
        %{"type" => "read_ok", "messages" => messages},
        state
      )

    {:noreply, state}
  end

  @impl true
  def handle_info({"topology", msg, %{"topology" => node_neighbours}}, state) do
    state = reply(msg, %{"type" => "topology_ok"}, state)

    {:noreply, %{state | node_neighbours: node_neighbours}}
  end
end
