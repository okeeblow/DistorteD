require('securerandom') unless defined?(::SecureRandom)

# TODO: Remove this and the corresponding EOF reset once Ractors are no longer experimental.
bring_me_back = ::Warning[:experimental]
::Warning[:experimental] = false


# Components for requesting time-based UUIDs with guaranteed uniqueness.
::GlobeGlitter::CHRONO_SEEKER = ::Ractor::new do

  # ITU-T Rec. X.667 sez —
  #
  # 12.4   — Clock sequence
  # 12.4.1 — For the time-based version of the UUID, the Clock Sequence is used to help avoid duplicates
  #          that could arise when the value of Time is set backwards or if the Node value is changed.
  #          NOTE – The name "Clock Sequence" is appropriate for the time-based version of a UUID,
  #          but is also used for the contents of the corresponding value in the name-based and
  #          random-number-based versions of a UUID.
  # 12.4.2 — If the Time value is set backwards, or might have been set backwards (for example,
  #          while the system was powered off), then the UUID generator cannot know whether a UUID has
  #          already been generated with Time values larger than the value to which the Time is now set.
  #          In such situations, the Clock Sequence value shall be changed.
  #          NOTE – If the previous value of the Clock Sequence is known, it can be just incremented;
  #          otherwise it should be set to a cryptographic-quality random or pseudo-random value.
  # 12.4.3 — Similarly, if the Node value changes (for example, because a network card has been moved
  #          between machines), the Clock Sequence value shall be changed.
  # 12.4.4 — The Clock Sequence shall be originally (that is, once in the lifetime of a system producing UUIDs)
  #          initialized to a random number that is not derived from the Node value.
  #          NOTE – This is in order to minimize the correlation across systems, providing maximum protection
  #          against MAC addresses that may move or switch from system to system rapidly.
  # 12.4.5 — For the name-based version of the UUID, the Clock Sequence shall be a 14-bit value constructed
  #          from a name as specified in clause 14.
  # 12.4.6 — For the random-number-based version of the UUID, the Clock Sequence shall be a randomly or pseudo-
  #          randomly generated 14-bit value as specified in clause 15.

  MAX_SEQUENCE = 0b11111111111111  # 14-bit
  sequence = ::SecureRandom::random_number(MAX_SEQUENCE)

  while true do
    # TODO: Reset sequence if MAC-based `node` value changes,
    #       even though we prefer non-identifiable random `node`.
    # TODO: Detect backwards time changes and reset sequence.
    sequence = sequence.eql?(MAX_SEQUENCE) ? 1 : sequence.succ
    ::Ractor::yield(sequence)
  end

end

::Warning[:experimental] = bring_me_back
