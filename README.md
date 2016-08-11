# Bucket

This is me, after years with an Object Oriented mindset, trying to understand how state is managed in a functional language like Elixir.

In the `lib` directory, there are several implementations of a `Bucket` module. It just wraps a dictionary and cat get and put elements on it by key, or consult the current state (dictionary). Completely useless, just a very simple example where state has to be kept. My personal notes are tangled between the code.

The order in which the files should be read is:

* functional
* server
* one_server
* generic_server
* gen_server
* agent

Sorry if something is wrong. Please, tell me if you know. This is not very clean nor 100% polished at all, they are just notes I needed and that I want to share just in case somebody is in the same point. If so and you want to discuss about something I'll be happy to learn together.

I needed to order these ideas while reading the great, great book [Elixir in Action](https://www.manning.com/books/elixir-in-action) by [Saša Jurić](http://www.theerlangelist.com/).
