## Tinychat

A tiny little eventmachine based chat server

# Instructions
* Install: `bundle install`
* Test: `ruby tinychat_test.rb`
* Run: `PORT=2428 ruby tinychat.rb`

# Things of note
* Theres a fun little test harness here that spins up a couple instances and uses them via a TCPSocket to test. The one failing test is for cross-instance communication, which will pass once that's added to the persistence mechanism.
* Eventmachine is a reactor that runs very quickly as long as you don't block it. Any IO must be done asynchronously.
* Yajl was used here via the gems ruby bindings, providing us an easy and fast streaming json parser
* The persistence mechanism is abstracted to be able to swap in different implementations, right now it's very dumb
* By plugging in a persistance mechanism that provides some sort of publishing mechanism, that alone will allow this server to scale accross proceses or machines

# Todo Yet
* A real persistence.rb implementation, likely using redis via em-hiredis and taking advantage of sorted sets using ZADD and
ZRANGEBYSCORE for time based querying
