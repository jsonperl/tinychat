## Tinychat

A tiny little eventmachine based chat server

# Instructions
* Install: `bundle install`
* Test: `ruby tinychat_test.rb`
* Run: `PORT=2428 ruby tinychat.rb`

# Things of note
* Theres a fun little test harness here that spins up a couple instances and uses them via a TCPSocket to test.
* Eventmachine is a reactor that runs very quickly as long as you don't block it. Any IO must be done asynchronously.
* Yajl was used here via the gems ruby bindings, providing us an easy and fast streaming json parser
* The persistence mechanism is abstracted to be able to swap in different implementations. It's setup to use redis, but can use an in-memory implementation provided.
