defmodule GossipGlomers.Node do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      @impl GenServer
      def init(nil) do
        pid = self()

        Task.start_link(fn ->
          IO.stream(:stdio, :line)
          |> Enum.each(fn msg ->
            msg
            |> Jason.decode!()
            |> then(fn %{"body" => %{"type" => msg_type} = body} = msg ->
              send(pid, {msg_type, msg, body})
            end)
          end)
        end)

        {:ok, nil}
      end

      def start_link([]) do
        GenServer.start_link(__MODULE__, nil)
      end

      @impl true
      def handle_info({"init", msg, body}, state) do
        reply(msg, Map.put(body, "type", "init_ok"))

        {:noreply, state}
      end

      defp reply(%{"src" => dest, "dest" => src, "body" => %{"msg_id" => msg_id}}, body) do
        %{
          src: src,
          dest: dest,
          body: Map.put(body, "in_reply_to", msg_id)
        }
        |> Jason.encode!()
        |> IO.puts()
      end
    end
  end
end
