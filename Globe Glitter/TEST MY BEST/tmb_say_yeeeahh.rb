require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitterSayYeeeahh < Test::Unit::TestCase

  # See comment on `::GlobeGlitter#to_s` for why this is in US-ASCII.
  PARTITION_SYSTEM_GUID = ::String::new("c12a7328-f81f-11d2-ba4b-00a0c93ec93b", encoding: Encoding::US_ASCII)

  # These are not tests for GloveGlitter code directly but are here to validate
  # decisions made during its development.
  # That is, if Ruby stdlib behavior changes, we should change with it.
  def test_assumptions
    # `::GlobeGlitter#to_s` emits `::Encoding::US_ASCII` like stdlib classes.
    assert_equal(::Encoding::US_ASCII, 333.to_s.encoding)
    assert_equal(::Encoding::US_ASCII, 333.to_f.to_s.encoding)
    assert_equal(::Encoding::US_ASCII, 69.420.to_s.encoding)
    assert_equal(::Encoding::US_ASCII, ::Time::now.to_s.encoding)
  end

  # ITU-T Rec. X.667 sez —
  #
  # “A UUID can be used as the primary integer value of a Joint UUID arc using the single integer value of the UUID.
  #  The hexadecimal representation of the UUID can also be used as a non-integer Unicode label for the arc.
  #  EXAMPLE — The following is an example of the use of a UUID to form an IRI/URI value: 
  #            "oid:/UUID/f81d4fae-7dec-11d0-a765-00a0c91e6bf6"”
  def test_to_oid_s
    assert_equal(
      "oid:/UUID/f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
      ::GlobeGlitter::new("f81d4fae-7dec-11d0-a765-00a0c91e6bf6").to_oid_s,
    )
  end

end
