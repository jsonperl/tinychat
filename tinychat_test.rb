require_relative "test_setup"

class TinyChatTest < Test::Unit::TestCase
  def test_broadcasts_messages
    alice = connect
    bob = connect

    msg = { sender: "Alice", msg: "Hello Bob!", client_time: time }
    alice.send_msg msg

    assert_receipt alice, msg
    assert_receipt bob, msg
  end

  # TODO
  def test_broadcasts_horizontally
    alice = connect(0)
    bob = connect(1)

    msg = { sender: "Alice", msg: "Hello Bob!", client_time: time }

    alice.send_msg msg
    assert_receipt bob, msg
  end

  def test_history
    alice = connect
    bob = connect

    bob.send_msg sender: "Bob", msg: "This is history", client_time: time
    bob.send_msg sender: "Alice", msg: "This is history", client_time: time
    alice.send_msg command: "history", client_time: 1477084767, since: time - 5000

    results = get_history_message(alice)

    assert(results.count == 2, "History should have 2 items and has #{results.count}")
    assert(is_match?(results[-2], { sender: "Bob", msg: "This is history" } ))
    assert(is_match?(results[-1], { sender: "Alice", msg: "This is history" } ))
  end

  def test_empty_history
    alice = connect
    alice.send_msg command: "history", client_time: 1477084767, since: time
    assert_last_message alice, []
  end

end
