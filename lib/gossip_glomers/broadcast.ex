defmodule GossipGlomers.Broadcast do
  use GossipGlomers.Node

  def init_state do
    %{messages: %{}, node_neighbours: %{}}
  end

  @impl true
  def handle_info(
        {"broadcast", %{"src" => src} = msg, %{"message" => message} = body},
        %{node_id: node_id, node_neighbours: node_neighbours, messages: messages} = state
      ) do
    seen_from_this_source =
      messages
      |> Map.get(message, [])

    neighbours_to_alert =
      node_neighbours
      |> Map.get(node_id, [])
      |> Enum.reject(&Enum.member?(seen_from_this_source, &1))

    state =
      Enum.reduce(neighbours_to_alert, state, fn neighbour, state ->
        send_msg(neighbour, body, state)
      end)
      |> then(&reply(msg, %{"type" => "broadcast_ok"}, &1))

    {:noreply,
     %{
       state
       | messages:
           Map.update(messages, message, [src], fn sources ->
             if(
               Enum.member?(sources, src),
               do: sources,
               else: [src | sources]
             )
           end)
     }}
  end

  @impl true
  def handle_info({"read", msg, _body}, %{messages: messages} = state) do
    state =
      reply(
        msg,
        %{"type" => "read_ok", "messages" => Map.keys(messages)},
        state
      )

    {:noreply, state}
  end

  @impl true
  def handle_info({"topology", msg, %{"topology" => node_neighbours}}, state) do
    state = reply(msg, %{"type" => "topology_ok"}, state)

    {:noreply, %{state | node_neighbours: node_neighbours}}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.info("unexpected: #{inspect(msg)}")

    {:noreply, state}
  end
end
