defmodule GossipGlomers.Echo do
  use GossipGlomers.Node

  @impl true
  def handle_info({"echo", msg, _body}, state) do
    state = reply(msg, %{"type" => "echo_ok"}, state)

    {:noreply, state}
  end
end
