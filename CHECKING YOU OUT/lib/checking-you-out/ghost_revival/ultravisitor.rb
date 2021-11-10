
::CHECKING::YOU::OUT::ULTRAVISITOR = ::Ractor::make_shareable(
  proc { |square_window, hello_everything|
    feed_me_weird_things = square_window.call
    while message = ::Ractor::receive
      # Forward all messages to the real parser, and restart+retry on failure.
      begin
        feed_me_weird_things.send(message, move: true)
      rescue ::Ractor::ClosedError => rce
        # TOD0: Handle multiple recurring failures here since if a particular `::String`
        #       makes our parser raise an error then sending it again probably won't help.
        feed_me_weird_things = square_window.call
        retry
      end
    end
  }  # Ractor::new
)
