# Similar to OO objects... Instead of object allocation ,
# another BEAM process is created which loops through tail
# recursion to keep itself alive. The state is an argument of
# the loop function, and this function waits for messages
# (equivalent to object messages) to query or perform
# something with the state.
#
# From the outside, the state is mutating.
#
# Why this approach when we are all so used to objects and it
# is so easy to work with them? Usually, objects are in the
# same process than the caller. Here it is another process,
# so we gain concurrency. Why I want concurrency? There are
# several reasons:
#
# * Parallelism - The most named one and usually confused
# with concurrency itself. You only get it if you have multiple
# cores.
# * Architecture - Processes are architectural pieces,
# similar than objects but more independent because they
# don't run in the same process.
# * Distribution - Processes can run in the same machine or
# in another one.
# * Scalability - Thanks to distribution we can scale it easier.
# * Fault tolerance - A crash in a process does not needs to turn
# down the whole system.
# * High availability - Due to fault tolerance,
# scalability, etc.
#
# Look how state is kept for us. But We have to keep the
# server PID, because we can have multiple servers (like
# object instances).
#
# I.e.:
#
# server = Bucket.Server.start
# Bucket.Server.put(server, :key, :value)
# Bucket.Server.get(server, :key)
defmodule Bucket.Server do
  # Spawns the process and initializes the state (the
  # argument of the loop function). Returns the server PID
  # so that client can refer to the running instance
  def start do
    spawn(fn ->
      loop(HashDict.new)
    end)
  end

  # Client API functions. Pay attention to the fact that
  # get/2, put/3 and bucket/1 functions run on the client
  # process. They take the server PID and send to it the
  # internal message that it expects, hiding its complexity
  # from the client.
  #
  # get/2 is a synchronous call: before going on, it waits for
  # the response
  def get(server, key) do
    send(server, { self, :get, key } )
    receive do
      { :reply, value } -> value
    end
  end

  # put/3 is an asynchronous call: client can call it and go
  # on even if the petition has not finished.
  def put(server, key, value) do
    send(server, { :put, key, value } )
    nil
  end

  def bucket(server) do
    send(server, { self, :value })
    receive do
      { :reply, bucket } -> bucket
    end
  end

  # From now on, following functions are running on the
  # server process. Nothing wrong with it. Was it very
  # complicated we could split in two modules.
  #
  # loop/1 function is THE process function. It just waits
  # for messages and once they are processed it calls itself
  # again with the updated state. Very important to
  # understand: messages are processed in a synchronous
  # manner. Even if client can do asynchronous calls, server
  # processes it one at a time.  Client calls put/3 in an
  # asynchronous way, but if the server receives this and after a
  # get/2 from the same or other client, it first processes
  # put/3 and once it has finished then takes get/2.  This
  # is because mailbox is a FIFO queue.
  defp loop(bucket) do
    bucket = receive do
      message -> process_message(bucket, message)
    end
    loop(bucket)
  end

  # Multi-clause functions to process each kind of message.
  # This is just to keep loop/1 cleaner.
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
