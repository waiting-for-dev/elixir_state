# Fortunately, there is no need to implement the GenericServer, because the abstraction it
# represents is already given to us, and with more features, by gen_server OTP behaviour.
# An OTP behaviour expects our callback module to implement some functions, just like we
# have done so far with Bucket.GenericServer. To ease the implementation, Elixir bundles
# the GenServer module, which provide sensible defaults for some of that callback
# functions so that we don't need to implement all of them the most part of the times.
#
# I.e.:
#
# { :ok, server } = Bucket.GenServer.start
# Bucket.GenServer.put(server, :key, :value)
# Bucket.GenServer.get(server, :key)
defmodule Bucket.GenServer do
  use GenServer

  # To start the process now we have to provide two arguments: the callback module and an
  # extra parameter. This extra parameter is given to the init callback function, which
  # is, again, responsible of initializing the state. That way, the client has a chance to
  # have influence in the server initial state. In our situation this is irrelevant, so we
  # provide `nil`. Also, the response of GenServer.start/2 is { :ok, pid }
  def start do
    GenServer.start(__MODULE__, nil)
    # Through a `name` key in the third argument we can register a singleton server, like
    # we did in Bucket.OneServer
    # GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def get(server, key) do
    GenServer.call(server, { :get, key })
    # If we provide a third argument, it is taken as the timeout in milliseconds. Otherwise it is 5
    # seconds.
    # GenServer.call(server, { :get, key }, 10000)
  end

  def put(server, key, value) do
    GenServer.cast(server, { :put, key, value })
    nil
  end

  def bucket(server) do
    GenServer.call(server, { :bucket })
  end

  # As told before, the init function takes one argument that comes from the client. The
  # response also has a different format.
  #
  # If you want to disallow starting the server return { :error, reason }, which in turn
  # will be returned by GenServer.start
  def init(_) do
    { :ok, HashDict.new }
  end

  # handle_call takes as second argument the caller pid. We don't need it here. The
  # response is in the form `{ :reply, response, new_state }`
  def handle_call({ :get, key }, _, bucket) do
    { :reply, HashDict.get(bucket, key), bucket }
  end

  def handle_call({ :bucket }, _, bucket) do
    { :reply, bucket, bucket }
  end

  # handle_cast must return { :noreply, new_state }
  def handle_cast({ :put, key, value }, bucket) do
    { :noreply, HashDict.put(bucket, key, value) }
  end
end
