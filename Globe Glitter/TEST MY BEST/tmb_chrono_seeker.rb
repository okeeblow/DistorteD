require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)


class TestGlobeGlitterChronoSeeker < Test::Unit::TestCase

  # During normal operation the `sequence` should be initialized once
  # but then not increment unless the clock goes backwards, we request UUIDs
  # faster than their 100ns tick rate, or our primary 802.3 address changes.
  def test_clock_increments_and_sequence_does_not
    sequence_cat = ::GlobeGlitter::CHRONO_SEEKER.take
    111.times {
      # UUID time resolution is 100ns.
      # This has potential to still fail due to `::Kernel::sleep`'s lack of precision.
      # If we get failures here, try increasing the wait (maybe by another `* 100`?) such that
      # more-than-UUID-tick-rate time will have elapsed between calls to `CHRONO_SEEKER.take`.
      ::Kernel::sleep(
        1 / ::GlobeGlitter::CHRONO_DIVER::NANOSECONDS_IN_SECOND *
          ::GlobeGlitter::CHRONO_DIVER::GREGORIAN_UUID_TICK_RATE
      )
      cat_sequence = ::GlobeGlitter::CHRONO_SEEKER.take
      assert_equal(sequence_cat, cat_sequence)
      sequence_cat = cat_sequence
    }
  end

  # TODO: Figure out how to test the cases where `sequence` *should* increment:
  #       - when clock moves backwards or hasn't moved since previous UUID request.
  #       - when the system's primary 802.3 address changes.
  #
  #       Refinements won't work because they only refine the `using` context,
  #       and we need to patch another context's use of `::Time::now`.
  #       Monkey-patching also doesn't seem to work when that other context
  #       is a `::Ractor` v(._. )v
  #
  #       I have manually verified the expected behavior by forcing the conditionals
  #       in `CHRONO_SEEKER` to `if true`/`unless false`, but I want a repeatable test.

end
