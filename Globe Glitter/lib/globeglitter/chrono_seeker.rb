require('securerandom') unless defined?(::SecureRandom)
require('xross-the-xoul/network') unless defined?(::XROSS::THE::NETWORK)

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

  MAX_SEQUENCE = 0b11111111111111  # 14-bit

  # Tracking variables to detect backwards clock changes and network card changes.
  time_to_empress = ::Time::now.utc
  world_vertex = ::XROSS::THE::NETWORK::interface_addresses.first

  # TOD0: If I wanted to read a stored sequence from non-volatile storage, I would do it here.
  #
  # Examples of implementations with non-volatile sequence storage:
  # - Ruby `uuid` Gem uses `#Dir.tmpdir/ruby-uuid` or `~/.ruby-uuid`:
  #    https://github.com/assaf/uuid#label-UUID+State+File
  # - Ruby `uuidtools` Gem seems to have thought about it but neglected to implement it
  #   based on the presence of a `@@state_file = nil` Class variable:
  #   https://github.com/sporkmonger/uuidtools/blob/3a5ac196697349d0f22bd289cbe85513f4b5b7a8/lib/uuidtools.rb#L67
  # - Perl `Data::UUID` uses `/var/tmp/.UUID_{STATE_NODEID}`, or the same files in any other directory
  #   given at install-time:  https://github.com/bleargh45/Data-UUID
  # - Lunix's `util-linux/libuuid` uses `/var/tmp/libuuid/clock.txt`:
  #   https://github.com/util-linux/util-linux/blob/e0bea4dfa85d3759ca7c2b6da1de6b4ca67d63cf/libuuid/src/uuidP.h#L42
  # - Apollo NCS (their portable implementation of their own NCA spec) used
  #   `/tmp/last_uuid` on UNIX systems and `sys$scratch:last_uuid.dat` on VMS:
  #   https://stuff.mit.edu/afs/athena/astaff/project/opssrc/quotasrc/src/ncs/nck/uuid.c

  # 12.4.4 — The Clock Sequence shall be originally (that is, once in the lifetime of a system producing UUIDs)
  #          initialized to a random number that is not derived from the Node value.
  #          NOTE – This is in order to minimize the correlation across systems, providing maximum protection
  sequence_cat = ::SecureRandom::random_number(MAX_SEQUENCE)

  while true do
    # NOTE: This looks hacky because `::Ractor::yield` blocks, so first sequence yielded
    #       after a backwards clock change or a MAC change would be stale if we checked
    #       for those changes as part of the `while true` infinite loop.
    #       Work around that by modifying the `::yield`ed sequence in flight if need be.
    ::Ractor::yield(sequence_cat).yield_self {
      # 12.4.2 — If the Time value is set backwards, or might have been set backwards (for example,
      #          while the system was powered off), then the UUID generator cannot know whether a UUID has
      #          already been generated with Time values larger than the value to which the Time is now set.
      #          In such situations, the Clock Sequence value shall be changed.
      #          NOTE – If the previous value of the Clock Sequence is known, it can be just incremented;
      #          otherwise it should be set to a cryptographic-quality random or pseudo-random value.
      sequence_cat = (sequence_cat.succ % MAX_SEQUENCE) if time_to_empress >= ::Time::now.utc
      # 12.4.3 — Similarly, if the Node value changes (for example, because a network card has been moved
      #          between machines), the Clock Sequence value shall be changed.
      #          against MAC addresses that may move or switch from system to system rapidly.
      sequence_cat = (sequence_cat.succ % MAX_SEQUENCE) unless (
        world_vertex.eql?(::XROSS::THE::NETWORK::interface_addresses.first)
      )
      # TODO: Figure out how to unit test these. For now I have manually verified it
      #       in REPL with `if true`/`unless false`.
      # TOD0: If I wanted to store the incremented sequence to non-volatile storage,
      #       I would do it here.
    }
    time_to_empress = ::Time::now.utc
    world_vertex = ::XROSS::THE::NETWORK::interface_addresses.first
  end

end

::Warning[:experimental] = bring_me_back
