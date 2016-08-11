# Same than Bucket.Server, but with the difference that only
# one process can exist (a singleton).
#
# The server function, before entering the infinite loop,
# registers itself under a name. Then, client API functions
# don't need to take server PID as argument; they can just
# use the registered name.
#
# Nice, state and server reference are automatically
# managed, but we have to be sure only one server makes
# sense.
#
# I.e:
#
# Bucket.OneServer.start
# Bucket.OneServer.put(:key, :value)
# Bucket.OneServer.get(:key)
# Bucket.OneServer.bucket
defmodule Bucket.OneServer do
  def start do
    spawn(fn ->
      Process.register(self, __MODULE__)
      loop(HashDict.new)
    end)
  end

  def get(key) do
    send(__MODULE__, { self, :get, key } )
    receive do
      { :reply, value } -> value
    end
  end

  def put(key, value) do
    send(__MODULE__, { :put, key, value } )
    nil
  end

  def bucket do
    send(__MODULE__, { self, :value })
    receive do
      { :reply, bucket } -> bucket
    end
  end

  # Following is identical than in Bucket.Server, because
  # they are the functions run in the server process.
  defp loop(bucket) do
    bucket = receive do
      message -> process_message(bucket, message)
    end
    loop(bucket)
  end

  defp process_message(bucket, { caller, :get, key }) do
    value = HashDict.get(bucket, key)
    send(caller, { :reply, value })
    bucket
  end

  defp process_message(bucket, { :put, key, value }) do
    HashDict.put(bucket, key, value)
  end

  defp process_message(bucket, { caller, :value }) do
    send(caller, { :reply, bucket })
    bucket
  end
end
