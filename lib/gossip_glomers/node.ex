defmodule GossipGlomers.Node do
  defmacro __using__(_opts) do
    quote do
      use GenServer

      require Logger

      @impl true
      def init(_opts) do
        pid = self()

        Process.flag(:trap_exit, true)

        Task.start_link(fn ->
          IO.stream(:stdio, :line)
          |> Enum.each(fn msg ->
            msg
            |> then(fn msg ->
              Logger.info("incoming: #{msg}")
              msg
            end)
            |> Jason.decode()
            |> case do
              {:ok, %{"body" => %{"type" => msg_type} = body} = msg} ->
                Kernel.send(pid, {msg_type, msg, body})

              {:error, _} = err ->
                Kernel.send(pid, err)
            end
          end)
        end)

        state = %{node_id: nil, msg_id: 1}

        {:ok,
         if(function_exported?(__MODULE__, :init_state, 0),
           do:
             apply(__MODULE__, :init_state, [])
             |> Map.merge(state),
           else: state
         )}
      end

      @impl true
      def handle_info({"init", msg, %{"node_id" => node_id}}, state) do
        state = reply(msg, %{"type" => "init_ok"}, %{state | node_id: node_id})

        {:noreply, state}
      end

      @impl true
      def terminate(msg, state) do
        Logger.error("exiting: #{inspect(msg)}")

        {:exit, msg}
      end

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts)
      end

      defp send_msg(dest, body, %{node_id: node_id, msg_id: msg_id} = state) do
        %{src: node_id, dest: dest, body: Map.put(body, "msg_id", msg_id)}
        |> Jason.encode!()
        |> then(fn msg ->
          Logger.info("outgoing: #{msg}")
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
