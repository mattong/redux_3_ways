defmodule UsingAgent do
  use Agent

  def create_store(0, reducer) do
    Agent.start(fn -> %{reducer: reducer, state: 0, subscribers: []} end)
  end

  def dispatch(agent_pid, action) do
    Agent.update(agent_pid, fn %{reducer: reducer, state: value} = agent_state ->
      new_state = reducer.(value, action)

      Map.put(agent_state, :state, new_state)
    end)

    subscribers = Agent.get(agent_pid, fn %{subscribers: subscribers} -> subscribers end)

    Enum.map(subscribers, & &1.(agent_pid))
  end

  def get_state(agent_pid) do
    Agent.get(agent_pid, fn %{state: value} -> value end)
  end

  def subscribe(agent_pid, notifier) do
    Agent.update(agent_pid, fn %{subscribers: subscribers} = agent_state ->
      Map.put(agent_state, :subscribers, [notifier | subscribers])
    end)

    fn ->
      unsubscribe(agent_pid)
    end
  end

  def unsubscribe(agent_pid) do
    Agent.update(agent_pid, fn %{subscribers: subscribers} = agent_state ->
      [_head | subscribers] = subscribers
      Map.put(agent_state, :subscribers, subscribers)
    end)
  end
end
