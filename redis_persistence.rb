require "em-hiredis"

class RedisPersistence
  def connect
    # Local connection
    @redis = EM::Hiredis.connect
    @redis.pubsub.subscribe("msgs") do |msg|
      message_received(Marshal.load(msg))
    end
  end

  def on_receipt(&block)
    @callback = block
  end

  def add_message(msg)
    @redis.publish(:msgs, Marshal.dump(msg)) # Pub/sub
    @redis.zadd "msgset", msg["server_time"], Marshal.dump(msg)
  end

  def get_history(epoch)
    raise "Requires callback" unless block_given?
    @redis.zrangebyscore("msgset", epoch, 10000000000000) do |hist|
      yield hist.map{ |msg| Marshal.load(msg) }
    end
  end

  private

  def message_received(msg)
    @callback.call(msg) if @callback
  end
end