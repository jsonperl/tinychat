#!/usr/bin/env ruby
require "rubygems"
require "eventmachine"
require "yajl/yajl"
require_relative "memory_persistence"
require_relative "redis_persistence"

class TinyChat < EM::Connection
  # On a concurrent platform, we'd need to protect @@clients with a mutex.
  # This implementation using a reactor (Eventmachine) is very fast
  # but can be assumed to be constrained by Ruby's GIL, so we know
  # that multiple threads cannot access the data concurrently.
  @@clients = Array.new
  @@persistence = RedisPersistence.new
  @@persistence.on_receipt do |msg|
    @@clients.each { |c| c.deliver(msg) }
  end

  def self.persistence
    return @@persistence
  end

  def post_init
    @parser = Yajl::Parser.new
    @encoder = Yajl::Encoder.new
    @parser.on_parse_complete = method(:receive_json)

    @@clients.push(self)
  end

  def unbind
    @@clients.delete(self)
  end

  def receive_data(data)
    @parser << data
  end

  def receive_json(msg)
    command?(msg) ? self.exec_command(msg) : self.receive_msg(msg)
  end

  def receive_msg(msg)
    msg["server_time"] = (Time.now.to_f * 1000).to_i
    @@persistence.add_message(msg)
  end

  def command?(data)
    !data["command"].nil?
  end

  def exec_command(cmd)
    case cmd["command"]
    when "history"
      @@persistence.get_history(cmd["since"]) do |history|
        deliver(history)
      end
    end
  end

  def deliver(msg)
    send_data("#{@encoder.encode(msg)}\n")
  end

  def client_count
    @@connected_clients.size
  end
end

EM.run do
  EM.error_handler do |e|
    puts "Error raised during event loop: #{e.message}"
  end

  port = ENV["PORT"] || 2428

  Signal.trap("INT")  { EM.stop }
  Signal.trap("TERM") { EM.stop }

  puts "Starting server on port #{port}..."
  EM.start_server "localhost", port, TinyChat
  TinyChat.persistence.connect
end
