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
        assert_equal(::GlobeGlitter::BEHAVIOR_RANDOM, _2.last.behavior)
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

end
