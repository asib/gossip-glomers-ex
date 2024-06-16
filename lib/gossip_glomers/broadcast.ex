defmodule GossipGlomers.Broadcast do
  use GossipGlomers.Node

  @initial_ok_wait_time 100

  def init_state do
    %{messages: %{}, node_neighbours: %{}, awaiting_ok: MapSet.new()}
  end

  @impl true
  def handle_info(
        {"broadcast", %{"src" => src} = msg, %{"message" => message, "msg_id" => msg_id} = body},
        %{
          node_id: node_id,
          node_neighbours: node_neighbours,
          messages: messages
        } = state
      ) do
    seen_from_this_source = Map.get(messages, message, [])

    neighbours_to_alert =
      node_neighbours
      |> Map.get(node_id, [])
      |> Enum.reject(&(&1 == src || Enum.member?(seen_from_this_source, &1)))

    state =
      Enum.reduce(neighbours_to_alert, state, fn neighbour, state ->
        key = set_key(neighbour, msg_id)
        state = send_msg(neighbour, body, state)

        Process.send_after(
          self(),
          {
            :verify_ok,
            key,
            fn state -> send_msg(neighbour, body, state) end,
            @initial_ok_wait_time
          },
          @initial_ok_wait_time
        )

        %{state | awaiting_ok: MapSet.put(state.awaiting_ok, key)}
      end)
      |> then(&reply(msg, %{"type" => "broadcast_ok"}, &1))

    {:noreply,
     Map.put(
       state,
       :messages,
       Map.update(messages, message, [src], fn sources ->
         if(
           Enum.member?(sources, src),
           do: sources,
           else: [src | sources]
         )
       end)
     )}
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
  def handle_info(
        {"broadcast_ok", %{"src" => src} = _msg, %{"in_reply_to" => in_reply_to} = _body},
        %{awaiting_ok: awaiting_ok} = state
      ) do
    key = set_key(src, in_reply_to)

    awaiting_ok =
      if MapSet.member?(awaiting_ok, key) do
        MapSet.delete(awaiting_ok, key)
      else
        awaiting_ok
      end

    {:noreply, %{state | awaiting_ok: awaiting_ok}}
  end

  @impl true
  def handle_info(
        {:verify_ok, key, retry, wait_time},
        %{awaiting_ok: awaiting_ok} = state
      ) do
    state =
      if MapSet.member?(awaiting_ok, key) do
        wait_time = wait_time * 2
        Logger.info("retrying: #{inspect(key)}")

        state = retry.(state)
        Process.send_after(self(), {:verify_ok, key, retry, wait_time}, wait_time)

        state
      end

    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.info("unexpected: #{inspect(msg)}")

    {:noreply, state}
  end

  defp set_key(neighbour, msg_id) do
    {neighbour, msg_id}
  end
end
