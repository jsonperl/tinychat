class Persistence
  def initialize
    @msgs = []
  end

  def on_receipt(&block)
    @callback = block
  end

  def add_message(msg)
    @msgs << msg
    puts msg
    message_received(msg)
  end

  def get_history(epoch)
    raise "Requires callback" unless block_given?
    yield @msgs.select{ |msg| msg["server_time"] && msg["server_time"] > epoch }
  end

  private

  def message_received(msg)
    @callback.call(msg) if @callback
  end
end