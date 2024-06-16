defmodule GossipGlomers.UniqueId do
  use GossipGlomers.Node

  @impl true
  def handle_info({"generate", msg, body}, state) do
    reply(
      msg,
      body
      |> Map.put("type", "generate_ok")
      |> Map.put("id", Ecto.ULID.generate())
    )

    {:noreply, state}
  end
end
