require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

# See also:
# - https://github.com/benasher44/uuid/blob/master/src/commonTest/kotlin/UuidTest.kt
# - https://github.com/gofrs/uuid/blob/master/uuid_test.go
class TestGlobeGlitter < Test::Unit::TestCase

  def test_random_uuid
    assert_equal(
      333.times.with_object(::Array::new) {
        _2.push(::GlobeGlitter::random)
        # `random` identifiers should always be variant 1 version 4.
        assert_equal(_2.last.version, 4)
        assert_equal(_2.last.variant, 1)
      }.size,
      333,  # Ensure `random` doesn't generate any duplicates (up to a confidence point lol)
    )
  end

  def test_nil_uuid
    assert_equal(::GlobeGlitter::nil.to_s, "00000000-0000-0000-0000-000000000000")
  end

  def test_dont_parse_invalid_input
    assert_nil(::GlobeGlitter::try_convert(nil))
    assert_nil(::GlobeGlitter::try_convert("aabbccdd-eeff-gghh-iijj-kkllmmnnoopp"))
    assert_nil(::GlobeGlitter::try_convert("11223344-5566-7788-9900-aabbccddeef"))
    assert_nil(::GlobeGlitter::try_convert("11223344-5566-7788-9900-aabbccddeefff"))
    assert_nil(::GlobeGlitter::try_convert(1 << 129))
    assert_nil(::GlobeGlitter::try_convert(1 << 65, 1 << 65))
    assert_nil(::GlobeGlitter::try_convert(1 << 33, 1 << 17, 1 << 49))
  end

  #def to_a
  #https://learn.microsoft.com/en-us/dotnet/api/system.guid.tobytearray#examples

end
