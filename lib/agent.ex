# Agents are just simplified GenServer's. Instead of managing things through a callback
# module which must implement some callback functions, here we tell what to do through
# anonymous functions that are defined by the client but executed by the server.
#
# I.e.:
#
# {:ok, server} = Bucket.Agent.start
# Bucket.Agent.put(server, :key, :value)
# Bucket.Agent.get(server, :key)
defmodule Bucket.Agent do
  def start do
    # No callback module has to be given. The initial state is set through the anonymous
    # function
    Agent.start(fn -> HashDict.new end)
    # It also accepts process registration
    # Agent.start(fn -> HashDict.new end, name: __MODULE__)
  end

  def get(server, key) do
    # Like GenServer.call, but assuming the state does not change, so there is no need to
    # specify it again
    Agent.get(server, fn (bucket)-> HashDict.get(bucket, :key) end )
  end

  def bucket(server) do
    Agent.get(server, &(&1))
  end

  def put(server, key, value) do
    Agent.cast(server, fn (bucket)-> HashDict.put(bucket, key, value) end )
  end
end
