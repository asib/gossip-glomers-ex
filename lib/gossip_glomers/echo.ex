defmodule GossipGlomers.Echo do
  use GossipGlomers.Node

  @impl true
  def handle_info({"echo", msg, body}, state) do
    reply(msg, Map.put(body, "type", "echo_ok"))

    {:noreply, state}
  end
end
