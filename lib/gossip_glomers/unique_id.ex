defmodule GossipGlomers.UniqueId do
  use GossipGlomers.Node

  @impl true
  def handle_info({"generate", msg, _body}, state) do
    state =
      reply(
        msg,
        %{
          "type" => "generate_ok",
          "id" => Ecto.ULID.generate()
        },
        state
      )

    {:noreply, state}
  end
end
