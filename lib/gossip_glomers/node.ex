defmodule GossipGlomers.Node do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      @impl GenServer
      def init(nil) do
        pid = self()

        {:ok, log_file} =
          File.open("./out_#{Time.utc_now() |> Time.to_iso8601()}.log", [:write, :utf8])

        Task.start_link(fn ->
          IO.stream(:stdio, :line)
          |> Enum.each(fn msg ->
            msg
            |> then(fn msg ->
              IO.write(log_file, "incoming: #{msg}")
              msg
            end)
            |> Jason.decode!()
            |> then(fn %{"body" => %{"type" => msg_type} = body} =
                         msg ->
              Kernel.send(pid, {msg_type, msg, body})
            end)
          end)
        end)

        state = %{node_id: nil, msg_id: 1, log_file: log_file}

        {:ok,
         if(function_exported?(__MODULE__, :init_state, 0),
           do:
             apply(__MODULE__, :init_state, [])
             |> Map.merge(state),
           else: state
         )}
      end

      def start_link([]) do
        GenServer.start_link(__MODULE__, nil)
      end

      @impl true
      def handle_info({"init", msg, %{"node_id" => node_id}}, state) do
        state = reply(msg, %{"type" => "init_ok"}, %{state | node_id: node_id})

        {:noreply, state}
      end

      defp send_msg(dest, body, %{node_id: node_id, msg_id: msg_id, log_file: log_file} = state) do
        %{src: node_id, dest: dest, body: Map.put(body, "msg_id", msg_id)}
        |> Jason.encode!()
        |> then(fn msg ->
          IO.puts(log_file, "outgoing: #{msg}")
          msg
        end)
        |> IO.puts()

        %{state | msg_id: msg_id + 1}
      end

      defp reply(%{"src" => dest, "body" => %{"msg_id" => msg_id}}, body, state) do
        send_msg(dest, Map.put(body, "in_reply_to", msg_id), state)
      end
    end
  end
end
