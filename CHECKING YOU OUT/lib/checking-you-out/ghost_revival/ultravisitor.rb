# Supply this `proc` to `Ractor::new` to create a `Ractor` which supervises a wrapped inner `Ractor`.
::CHECKING::YOU::OUT::ULTRAVISITOR = ::Ractor::make_shareable(
  proc { |square_window, hello_everything|

    # Our first positional argument *must* be another `Proc` which creates our inner `Ractor`.
    feed_me_weird_things = square_window.call

    # Track the `Integer` hash of the last message successfully sent to the inner `Ractor`,
    # so if the next message encounters a `Ractor::ClosedError` we will know the hash of the cause.
    big_loada = nil

    # Forward all messages to the real parser, and restart+retry on failure.
    while message = ::Ractor::receive
      begin
        # Save the `#hash` before we `move` the message to the inner `Ractor` and can't access it.
        ill_descent = message.hash
        feed_me_weird_things.send(message, move: true)

        # Overwrite the previously-saved `#hash` iff the message-send succeeds.
        big_loada = ill_descent
      rescue ::Ractor::ClosedError => rce
        # Restart the inner `Ractor`.
        feed_me_weird_things = square_window.call
        # Discard any message causing consecutive crashes (by not `retry`ing).
        # TODO: Log the message which causes consecutive crashes.
        retry unless message.hash.eql?(big_loada)
      end
    end
  }  # Proc::new
)
