defmodule UsingProcess do
  def create_store(initial_state, reducer_function) do
    pid = spawn(fn -> loop(%{subscribers: [], state: initial_state}, reducer_function) end)

    {:ok, pid}
  end

  def dispatch(store_pid, action) do
    send(store_pid, {:dispatch, action, self()})

    receive do
      {:subscribers, subscribers} ->
        run_subscriber_functions(subscribers, store_pid)
    end
  end

  def get_state(store_pid) do
    send(store_pid, {:get, self()})

    receive do
      {:state, state} -> state
    end
  end

  def subscribe(store_pid, notifier) do
    send(store_pid, {:subscribe, notifier})

    fn ->
      send(store_pid, :unsubscribe)
    end
  end

  defp loop(state, reducer_function) do
    receive do
      {:dispatch, action, pid} ->
        new_state = reducer_function.(state.state, action)
        send(pid, {:subscribers, state.subscribers})

        loop(Map.put(state, :state, new_state), reducer_function)

      {:get, pid} ->
        send(pid, {:state, Map.get(state, :state)})
        loop(state, reducer_function)

      {:subscribe, notifier} ->
        state = Map.put(state, :subscribers, [notifier | state.subscribers])
        loop(state, reducer_function)

      :unsubscribe ->
        [_ | subscribers] = state.subscribers
        loop(Map.put(state, :subscribers, subscribers), reducer_function)

      {:get_store, pid, ref} ->
        send(pid, {ref, state})

        loop(state, reducer_function)

      _ ->
        loop(state, reducer_function)
    end
  end

  defp run_subscriber_functions(subscribers, store_pid) do
    Enum.map(subscribers, & &1.(store_pid))
  end
end
