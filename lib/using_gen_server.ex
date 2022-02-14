defmodule UsingGenServer do
  use GenServer

  def create_store(state, reducer) do
    GenServer.start_link(__MODULE__, %{state: state, reducer: reducer, subscribers: []})
  end

  def dispatch(gen_pid, action) do
    GenServer.cast(gen_pid, {:dispatch, action})

    subscribers = GenServer.call(gen_pid, :get_subscribers)

    Enum.map(subscribers, & &1.(gen_pid))
  end

  def get_state(gen_pid) do
    GenServer.call(gen_pid, :get_state)
  end

  def subscribe(gen_pid, notifier) do
    GenServer.cast(gen_pid, {:subscribe, notifier})

    fn ->
      GenServer.cast(gen_pid, :unsubscribe)
    end
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_state, _from, %{state: state} = gen_state) do
    {:reply, state, gen_state}
  end

  def handle_call(:get_subscribers, _from, %{subscribers: subscribers} = gen_state) do
    {:reply, subscribers, gen_state}
  end

  def handle_call(:get_store, _from, gen_state) do
    {:reply, gen_state, gen_state}
  end

  def handle_cast({:dispatch, action}, %{state: state, reducer: reducer} = gen_state) do
    new_state = reducer.(state, action)

    {:noreply, Map.put(gen_state, :state, new_state)}
  end

  def handle_cast({:subscribe, notifier}, %{subscribers: subscribers} = gen_state) do
    new_subscribers = [notifier | subscribers]

    {:noreply, Map.put(gen_state, :subscribers, new_subscribers)}
  end

  def handle_cast(:unsubscribe, %{subscribers: subscribers} = gen_state) do
    [_head | new_subscribers] = subscribers

    {:noreply, Map.put(gen_state, :subscribers, new_subscribers)}
  end
end
