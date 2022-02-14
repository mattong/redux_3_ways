defmodule ReduxTest do
  use ExUnit.Case, async: true

  setup do
    reducer = fn state, action ->
      case action.type do
        :add ->
          state + action.value
        :set ->
          action.value
        _ ->
          state
      end
    end

    {:ok, agent_store} = UsingAgent.create_store(0, reducer)
    {:ok, gen_store} = UsingGenServer.create_store(0, reducer)
    {:ok, process_store} = UsingProcess.create_store(0, reducer)

    {:ok,
     agent_store: agent_store,
     gen_store: gen_store,
     process_store: process_store}
  end

  # UsingProcess

  test "process dispatch updates the state", %{process_store: process_store} do
    UsingProcess.dispatch(process_store, %{ type: :add, value: 5 })
    assert UsingProcess.get_state(process_store) == 5
  end

  test "process subscribers gets notified and unsubscribed",
    %{process_store: process_store} do

    unsubscribe = UsingProcess.subscribe(process_store, fn store ->
      IO.puts "The state is #{UsingProcess.get_state(store)}"
    end)

    f = fn ->
      UsingProcess.dispatch(process_store, %{ type: :add, value: 10 })
    end

    assert ExUnit.CaptureIO.capture_io(f) == "The state is 10\n"
    assert UsingProcess.get_state(process_store) == 10

    unsubscribe.()
    assert ExUnit.CaptureIO.capture_io(f) == ""

    ref = make_ref()
    send(process_store, {:get_store, self(), ref})

    expected = %{subscribers: [], state: 20}
    assert_receive {^ref, expected}
  end

  # UsingGenServer

  test "gen dispatch updates the state", %{gen_store: gen_store} do
    UsingGenServer.dispatch(gen_store, %{ type: :add, value: 5 })
    assert UsingGenServer.get_state(gen_store) == 5
  end

  test "gen subscribers gets notified and unsubscribed",
    %{gen_store: gen_store} do

    unsubscribe = UsingGenServer.subscribe(gen_store, fn store ->
      IO.puts "The state is #{UsingGenServer.get_state store}"
    end)

    f = fn ->
      UsingGenServer.dispatch(gen_store, %{ type: :add, value: 10 })
    end

    assert ExUnit.CaptureIO.capture_io(f) == "The state is 10\n"
    assert UsingGenServer.get_state(gen_store) == 10

    unsubscribe.()
    assert ExUnit.CaptureIO.capture_io(f) == ""

    store = GenServer.call(gen_store, :get_store)
    assert store.state == 20
    assert store.subscribers == []
  end

  # UsingAgent

  test "agent dispatch updates the state", %{agent_store: agent_store} do
    UsingAgent.dispatch(agent_store, %{ type: :add, value: 5 })
    assert UsingAgent.get_state(agent_store) == 5
  end

  test "agent subscribers gets notified and unsubscribed",
    %{agent_store: agent_store} do

    unsubscribe = UsingAgent.subscribe(agent_store, fn store ->
      IO.puts "The state is #{UsingAgent.get_state store}"
    end)

    f = fn ->
      UsingAgent.dispatch(agent_store, %{ type: :add, value: 10 })
    end

    assert ExUnit.CaptureIO.capture_io(f) == "The state is 10\n"
    assert UsingAgent.get_state(agent_store) == 10

    unsubscribe.()
    assert ExUnit.CaptureIO.capture_io(f) == ""

    store = Agent.get agent_store, & &1
    assert store.state == 20
    assert store.subscribers == []
  end
end
