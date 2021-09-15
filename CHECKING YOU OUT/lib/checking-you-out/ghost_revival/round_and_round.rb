# Generate CYO `::Ractor` round-trip-messaging methods, e.g. the synchronous `:from_pathname`/`:from_postfix`.
# The outer lambda returns another lambda for use as the second argument to `::Module#define_method`.
#
# I used to have separate synchronous methods for various types of needles, but those methods became nearly-identical
# after introducing `EverlastingMessage`. This approach is kinda — idk, verbose? — but should help ward off bugs caused
# by e.g. hypothetical future changes to one of those methods not making it to the others.
#
# This approach should also allow us to generate additional round-trip methods for use in non-main `::Ractor`s
# where we can't refer to any class variables (e.g. the `instance_variable_name` on a `::Class` instance),
# but I have yet to test/confirm it.
# TODO: Test/confirm it.
::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND = ::Ractor.make_shareable(

  # Outer lambda takes arguments used to customize the inner lambda.
  ->(
    instance_variable_name,     # In what `IVar` should the generated method store its reusable `EverlastingMessage`?
    request_class,              # Into what `::Class` should we coerce `request_value`?
    *request_args,              # Positional arguments for `request_value` coercion.
    request_eql_method: :eql?,  # What method should our `request_class` use to determine `request_value` cache-hit?
    **request_kwargs            # Named arguments for `request_value` coercion?
  ) {

    # Use the customized inner lambda as the second argument to `Module#define_method` in `ROUND_AND_ROUND`'s calling context.
    ->(request_value, area_code: ::CHECKING::YOU::OUT::DEFAULT_AREA_CODE) {

      # Re-use a single CYO message envelope (`EverlastingMessage`) for round-trip requests to avoid
      # an additional allocation every time we call the generated method.
      # NOTE: We can *only* do this because it's a round-trip! See the additional note and IRB example below.
      self.instance_variable_set(
        # This is called "instance" variable, but it can be on a `::Class` instance too — they're the same thing!
        instance_variable_name,
        # The envelope itself is mutable, but its contents might not be.
        ::CHECKING::YOU::IN::EverlastingMessage.new(
          # Destination `::Ractor` where CYO will send the mutated `EverlastingMessage` envelope.
          # This can be any `::Ractor`, but using `::current` makes it a round-trip back to here.
          ::Ractor.current,
        )
      ) unless self.instance_variable_defined?(instance_variable_name)  # The above will only run once per method-instance.

      # Decide if we can re-use the cached response or if we need to round-trip to CYO's `::Ractor`.
      if (
        # `EverlastingMessage#request` and `#response` will always be `nil` before the first round-trip.
        # The customizable `request_eql_method` allows e.g. `::String`s to use `:start/end_with?` instead of plain `:eql?`.
        self.instance_variable_get(instance_variable_name).request&.send(request_eql_method, request_value) and
        not self.instance_variable_get(instance_variable_name).response.nil?
      ) then
        # No need to round-trip! Use the cached response.
        self.instance_variable_get(instance_variable_name).response
      else
        # …otherwise discard the previous `:request` and `:response` and get ready to Do The Thing.
        self.instance_variable_get(instance_variable_name).tap {
          # Wrap the generated-method's argument into the `::Class` defined at outer-lambda-call-time.
          # NOTE: This wrapping is important despite its explicit extra allocation:
          #       - Callers might want to keep using the `request_value` argument `::Object` by reference,
          #         so it would be inappropriate to `::Ractor#send(move: true)` it out from under them
          #         without at least doing a shallow-copy (`#dup` or `#initialize_copy`) anyway.
          #       - The "wrapper" `::Class` can implement custom equality and `#hash` methods
          #         for the wrapped value, e.g. `StickAround`'s case-optional `:eql?`.
          _1.request  = request_class.new(request_value, *request_args, **request_kwargs)
          # Never let a response to one trip leak into the next.
          # CYO itself will respond with `nil` for an unmatchable needle.
          _1.response = nil
        }

        # We can't refer to `instance_key` after it becomes a `::Ractor::MovedObject`,
        # so we need to track the `::Integer` hash of our request instance instead of the instance itself.
        wanted = self.instance_variable_get(instance_variable_name).request.hash
        self.areas[area_code].send(self.instance_variable_get(instance_variable_name), move: true)

        # CYO will `::Ractor#send(move: true)` the mutated envelope back to us so we can save it again,
        # but it will still be a `MovedObject` until *after* the `::Ractor::receive_if` block matches.
        #
        # NOTE: We must explicitly save the round-tripped `EverlastingMessage` back to the `instance_variable_name`,
        #       because the old reference will still be a `::Ractor::MovedObject` as far as this `::Ractor` is concerned!
        #       The returned `::Object` will have a different `__id__` despite not undergoing a second allocation:
        #
        #   irb(main):024:0> lol = "CHECKING YOU OUT 👀"                                       => "CHECKING YOU OUT 👀"
        #   irb(main):025:0> lol.object_id                                                     => 1340
        #   irb(main):026:0> r = ::Ractor.new { ::Ractor.yield(::Ractor.receive, move: true) } => #<Ractor:#7 (irb):26 blocking>
        #   irb(main):027:0> r.send(lol, move: true)                                           => #<Ractor:#7 (irb):26 blocking>
        #   irb(main):028:0> lol.object_id
        #   (irb):28:in `method_missing': can not send any methods to a moved object (Ractor::MovedError)
        #           from (irb):28:in `<main>'
        #           from ./bin/repl:11:in `<main>'
        #   irb(main):029:0> rofl = r.take                                                     => "CHECKING YOU OUT 👀"
        #   irb(main):030:0> rofl.object_id                                                    => 1360
        self.instance_variable_set(
          instance_variable_name,
          ::Ractor.receive_if {
            _1.is_a?(::CHECKING::YOU::IN::EverlastingMessage) and _1.request.hash == wanted
          }
        )
        # The generated method should return just the `#response`, not the whole `EverlastingMessage`.
        self.instance_variable_get(instance_variable_name).response
      end
    }
  }

)  # ::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND = ::Ractor.make_shareable(
