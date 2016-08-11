# If you stop and think, you see that a server, simple or
# complicated, is always doing the same:
#
# * Spawning a process
# * Running an infinite loop in the process
# * Keeping the state as a loop function argument
# * Listening for messages, which can be of two kinds:
#   * Messages that expect a response, let's name them 'calls'
#   * Messages that do not expect a response, let's name them 'casts'
#
# So, why not generalising this behaviour? To do so, we
# implement a generic server which takes a plug-in module to
# which it delegates some callbacks.  That callback
# functions in the plug-in module are the ones that
# implement the actual specific work.
defmodule GenericServer do
  # As always, start/1 function spawns the process. But this
  # time it takes as argument the callback module. It
  # is expected that the callback module implements an init/0
  # function which returns the initial state
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init
      loop(callback_module, initial_state)
    end)
  end

  # call/2 and cast/2 are API functions to be used by the
  # callback module. They just wrap the two kinds of
  # messages the loop function expects and make the
  # interface easier.
  #
  # call/2 is meant to be used when you want to perform some
  # synchronous request. For this reason, its implementation
  # calls the server providing client PID, so that it can
  # response with something, to which the implementation
  # is waiting in the receive block.
  def call(server, request) do
    send(server, { :call, request, self } )

    receive do
      { :response, response } -> response
    end
  end

  # cast/2, in contrast, is asynchronous. It just delegates
  # the request to the server and returns immediately,
  # without waiting for anything.
  def cast(server, request) do
    send(server, { :cast, request })
  end

  # The loop function waits for two kinds of messages: :call
  # or :cast.  If it is a call the message has to contain
  # also the caller PID so it can send the response.
  #
  # When it is a call, the request is delegated to a
  # `handle_call` callback function, along with the current
  # state. This function is supposed to return two things: a
  # response for the client and the updated state.
  #
  # If it is a cast, the request is delegated to a
  # `handle_cast` callback function, along with the current
  # state. This function has to return the updated state.
  defp loop(callback_module, current_state) do
    updated_state = receive do
      { :call, request, caller } ->
        { response, updated_state } = callback_module.handle_call(request, current_state)
        send(caller, { :response, response })
        updated_state
      { :cast, request } ->
        callback_module.handle_cast(request, current_state)
    end
    loop(callback_module, updated_state)
  end
end

# And here it goes the callback module for our Bucket. It
# just has to implement the expected functions. It also
# provides API functions so that the client does not need to
# be aware about the use of GenericServer.
#
# I.e:
#
# server = Bucket.GenericServer.start
# Bucket.GenericServer.put(server, :key, :value)
# Bucket.GenericServer.get(server, :key)
defmodule Bucket.GenericServer do
  def start do
    GenericServer.start(__MODULE__)
  end

  def get(server, key) do
    GenericServer.call(server, { :get, key })
  end

  def put(server, key, value) do
    GenericServer.cast(server, { :put, key, value })
    nil
  end

  def bucket(server) do
    GenericServer.call(server, { :bucket })
  end

  def init do
    HashDict.new
  end

  def handle_call({ :get, key }, bucket) do
    { HashDict.get(bucket, key), bucket }
  end

  def handle_call({ :bucket }, bucket) do
    { bucket, bucket }
  end

  def handle_cast({ :put, key, value }, bucket) do
    HashDict.put(bucket, key, value)
  end
end
