require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

# See also:
# - https://github.com/benasher44/uuid/blob/master/src/commonTest/kotlin/UuidTest.kt
# - https://github.com/gofrs/uuid/blob/master/uuid_test.go
class TestGlobeGlitter < Test::Unit::TestCase

  def test_random_uuid
    assert_equal(
      333,  # Ensure `random` doesn't generate any duplicates (up to a confidence point lol)
      333.times.with_object(::Array::new) {
        _2.push(::GlobeGlitter::random)
        # `random` identifiers should always be structure 1 version 4.
        assert_equal(::GlobeGlitter::RULES_RANDOM, _2.last.rules)
        assert_equal(::GlobeGlitter::STRUCTURE_ITU_T_REC_X_667, _2.last.structure)
      }.uniq.size,
    )
  end

  def test_time_uuid
    t1 = ::GlobeGlitter::from_time
    t2 = ::GlobeGlitter::from_time
    assert_operator(t1, :<, t2)
  end

  def test_nil_uuid
    assert_equal("00000000-0000-0000-0000-000000000000", ::GlobeGlitter::nil.to_s)
  end

  # https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-04.html#name-max-uuid
  def test_max_uuid
    assert_equal("ffffffff-ffff-ffff-ffff-ffffffffffff", ::GlobeGlitter::max.to_s)
  end

  def test_dont_parse_invalid_input
    assert_nil(::GlobeGlitter::try_convert(nil))

    # Non-hex characters in `::String` UUID representation.
    assert_nil(::GlobeGlitter::try_convert("aabbccdd-eeff-gghh-iijj-kkllmmnnoopp"))

    # Too short
    assert_nil(::GlobeGlitter::try_convert("11223344-5566-7788-9900-aabbccddeef"))

    # Too long
    assert_nil(::GlobeGlitter::try_convert("11223344-5566-7788-9900-aabbccddeefff"))
    assert_nil(::GlobeGlitter::try_convert(1 << 129))
    assert_nil(::GlobeGlitter::try_convert(1 << 65, 1 << 65))
    assert_nil(::GlobeGlitter::try_convert(1 << 33, 1 << 17, 1 << 49))
  end

  def test_bytes
    # Wikipedia https://en.wikipedia.org/wiki/Universally_unique_identifier#Encoding sez —
    # “The binary encoding of UUIDs varies between systems. Variant 1 UUIDs, nowadays the most common structure,
    #  are encoded in a big-endian format. For example, `00112233-4455-6677-8899-aabbccddeeff` is encoded as
    #  the bytes `00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff`.”
    assert_equal(
      [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF],
      ::GlobeGlitter::new("00112233-4455-6677-8899-aabbccddeeff").bytes
    )

    # “Variant 2 UUIDs, historically used in Microsoft's COM/OLE libraries, use a little-endian format,
    #  but appear mixed-endian with the first three components of the UUID as little-endian and last two big-endian,
    #  due to the missing byte dashes when formatted as a string. For example, `00112233-4455-6677-c899-aabbccddeeff`
    #  is encoded as the bytes `33 22 11 00 55 44 77 66 88 99 aa bb cc dd ee ff`.
    #  See the section on Variants for details on why the '88' byte becomes 'c8' in Variant 2.”
    assert_equal(
      [0x33, 0x22, 0x11, 0x00, 0x55, 0x44, 0x77, 0x66, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF],
      ::GlobeGlitter::new("00112233-4455-6677-8899-aabbccddeeff", structure: ::GlobeGlitter::STRUCTURE_MICROSOFT).bytes
    )

    # Example values from https://learn.microsoft.com/en-us/dotnet/api/system.guid.tobytearray#examples
    assert_equal(
      [0xC9, 0x8B, 0x91, 0x35, 0x6D, 0x19, 0xEA, 0x40, 0x97, 0x79, 0x88, 0x9D, 0x79, 0xB7, 0x53, 0xF0],
      ::GlobeGlitter::new("35918bc9-196d-40ea-9779-889d79b753f0", structure: ::GlobeGlitter::STRUCTURE_MICROSOFT).bytes
    )
  end

end
