# Just module functions that accept the current state as
# argument to query or to do something with it (obviously, in
# a non-destructive way because of immutability).
#
# It is the most basic approach, where there is nothing that
# keeps the state for you. It is the client who must keep it
# and provide it again each time to perform the following
# operation.
#
# I.e.:
#
# bucket = Bucket.Functional.start
# bucket = Bucket.Functional.put(bucket, :key, :value)
# value = Bucket.Functional.get(bucket, :key)
defmodule Bucket.Functional do
  def start do
    HashDict.new
  end

  def get(bucket, key) do
    HashDict.get(bucket, key)
  end

  def put(bucket, key, value) do
    HashDict.put(bucket, key, value)
  end

  # Nonsense. You provide the state so the function returns
  # what you gave to it.
  def bucket(bucket) do
    bucket
  end
end
