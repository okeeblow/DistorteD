module ::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND
  def send(query, area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE)
    self.areas[area_code].send(query)
  end
  def [](
    query,
    area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current,
    coerce: nil
  )
    return if query.nil? or (query&.empty? if query.respond_to?(:empty?))
    message = ::CHECKING::YOU::OUT::EverlastingMessage::new(
      coerce.nil? ? query.dup : coerce.new(query),
      receiver
    )
    wanted = message.erosion_mark
    self.areas[area_code].send(message, move: true)
    ::Ractor::receive_if {
      _1.is_a?(::CHECKING::YOU::IN::EverlastingMessage) and _1.erosion_mark == wanted
    }.be_lovin if receiver == ::Ractor::current
  end

  def from_postfix(
    query,
    area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current
  )
    self.[](query, area_code: area_code, receiver: receiver, coerce: ::CHECKING::YOU::OUT::StickAround)
  end

  def from_pathname(
    query,
    area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE,
    receiver: ::Ractor::current
  )
    self.[](query, area_code: area_code, receiver: receiver, coerce: ::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O)
  end
end  # ::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND = ::Ractor.make_shareable(
