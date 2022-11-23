module ::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND
  def send(query, area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE)
    ::CHECKING::YOU::OUT::GHOST_REVIVAL::AREAS[area_code].send(query)
  end

  # We differentiate the `::Integer` limits for the two queues based on sign.
  # Positive values apply to an area's loaded-types cache,
  # and negative values apply to an area's query-response cache.
  # The area `Ractor`'s message-handling loop will undo the sign flip for the negatives.
  #
  # I ended up doing it this way since I couldn't subclass `Integer` due to the interpreter
  # treating them as immediates, but we can get away with this due to having only two queues.
  def set_type_cache_size(limit, area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE)
    # The query cache is *effectively* limited in size because there will only ever be so many
    # type definitions in our available `shared-mime-info` XML packages.
    return ::CHECKING::YOU::OUT::GHOST_REVIVAL::AREAS[area_code] unless limit.eql?(::Float::INFINITY) or limit.is_a?(::Integer)
    ::CHECKING::YOU::OUT::GHOST_REVIVAL::AREAS[area_code].send(
      case limit
      when ::Integer then limit.positive? ? limit : -limit
      else limit
      end
    )
  end
  def set_query_cache_size(limit, area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE)
    # Query cache size will be reset to `DEFAULT_QUERY_CACHE_SIZE` if given `0`.
    return ::CHECKING::YOU::OUT::GHOST_REVIVAL::AREAS[area_code] unless limit.is_a?(::Integer)
    ::CHECKING::YOU::OUT::GHOST_REVIVAL::AREAS[area_code].send(limit.negative? ? limit : -limit)
  end

  # Control `Ractor#send(move: true/false)` based on whether or not we are coercing the given input to a new `Class`.
  # This is to work around the inability for `Ractor::make_shareable` to `#freeze` the `IO` stream in a `Wild_I/O`,
  # avoiding a `Ractor::MovedError` if we tried to use the same query `Object` twice in a row.
  #
  # Compare explicit `move: true`:
  #   irb> lumix = Pathname::new('/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/TEST MY BEST/Try 2 Luv. U/x-content/image-dcf/LUMIX')
  #   irb> CYO::from_pathname(lumix).description => "digital photos"
  #   irb> CYO::from_pathname(lumix).description
  #   /home/okeeblow/Works/DistorteD/CHECKING YOU OUT/lib/checking-you-out/ghost_revival/round_and_round.rb:11:in `p':
  #     undefined method `inspect' for #<Ractor::MovedObject:0x0000564fbcdd2040> (NoMethodError)
  #         from /home/okeeblow/Works/DistorteD/CHECKING YOU OUT/lib/checking-you-out/ghost_revival/round_and_round.rb:11:in `[]'
  #         from /home/okeeblow/Works/DistorteD/CHECKING YOU OUT/lib/checking-you-out/ghost_revival/round_and_round.rb:37:in `from_pathname'
  #         from (irb):3:in `<main>'
  #         from ./bin/repl:11:in `<main>'
  #
  # …to `move: coerce.nil?`:
  #   irb> lumix = Pathname::new('/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/TEST MY BEST/Try 2 Luv. U/x-content/image-dcf/LUMIX')
  #   irb> CYO::from_pathname(lumix).description => "digital photos"
  #   irb> CYO::from_pathname(lumix).description => "digital photos"
  def [](
    query,
    area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current,
    coerce: nil
  )
    return if query.nil? or (query&.empty? if query.respond_to?(:empty?))
    message = ::CHECKING::YOU::OUT::EverlastingMessage::new(
      coerce.nil? ? query.dup : (
        # If we're given e.g. an `::Array`, coerce everything it contains.
        # Otherwise coerce the given value itself.
        query.is_a?(::Enumerable) ? query.dup.map!(&coerce.method(:new)) : coerce.new(query)
      ),
      receiver
    )
    wanted = message.erosion_mark
    ::CHECKING::YOU::OUT::GHOST_REVIVAL::AREAS.call(area_code).send(message, move: coerce.nil?)
    ::Ractor::receive_if {
      _1.is_a?(::CHECKING::YOU::IN::EverlastingMessage) and _1.erosion_mark == wanted
    }.in_motion if receiver == ::Ractor::current
  end

  def from_postfix(
    query,
    area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current
  )
    self.[](query, area_code:, receiver:, coerce: ::CHECKING::YOU::OUT::DeusDextera)
  end

  def from_pathname(
    query,
    area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current
  )
    self.[](query, area_code:, receiver:, coerce: ::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O)
  end

  def from_fourcc(
    query,
    area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current
  )
    self.[](query, area_code:, receiver:, coerce: ::CHECKING::YOU::OUT::Miracle4::FourLeaf)
  end
end  # ::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND = ::Ractor.make_shareable(
