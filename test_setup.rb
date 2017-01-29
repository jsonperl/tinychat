require "test/unit"
require "socket"
require "json"
require "hiredis"

PORTS = [2428, 2429]
MSGWAIT = 0.2

Test::Unit.at_start do
  @pids = PORTS.map{ |port| Process.spawn("TEST=true PORT=#{port} ruby tinychat.rb") }
  sleep 1
end

Test::Unit.at_exit do
  @pids.each { |pid| Process.kill(:SIGINT, pid) }
end

class Client
  attr_reader :msgs

  def initialize(server_no = 0)
    @client = TCPSocket.new "localhost", PORTS[server_no]
    @msgs = []
    @thread = Thread.start do
      while line = @client.gets
        @msgs << JSON.parse(line.strip)
      end
    end
  end

  def send_msg(msg)
    @client.puts(JSON.generate(msg))
  end

  def close
    @client.close
    @thread.kill
  end
end

class TinyChatTest < Test::Unit::TestCase
  Signal.trap("INT")  { teardown }

  def connect(server_no = 0)
    Client.new(server_no).tap { |c| @connections << c }
  end

  def setup
    cleardb!
    @connections = []
  end

  def teardown
    @connections.each(&:close)
    @connections.clear
    cleardb!
  end

  def time
    (Time.now.to_f * 1000).to_i
  end

  def is_match?(msg, expected)
    return false if msg.nil?
    expected.to_a == msg.map{|k,v| [k.to_sym, v]} & expected.to_a
  end

  def assert_receipt(client, expected)
    sleep MSGWAIT

    received = client.msgs.any? { |msg| is_match?(msg, expected) }
    assert received, "Msg not received #{expected}"
  end

  def assert_last_message(client, msg)
    sleep MSGWAIT

    assert client.msgs.last == msg, "Msg not received #{msg}"
  end

  def get_history_message(client)
    sleep MSGWAIT
    client.msgs.detect { |m| m.is_a? Array }
  end

  def cleardb!
    redis = Hiredis::Connection.new
    redis.connect("127.0.0.1", 6379)

    redis.write ["DEL", "tst:msgset"]
    redis.read
  end
end
