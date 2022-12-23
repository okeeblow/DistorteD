require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

# See also:
# - https://github.com/benasher44/uuid/blob/master/src/commonTest/kotlin/UuidTest.kt
# - https://github.com/gofrs/uuid/blob/master/uuid_test.go
class TestGlobeGlitter < Test::Unit::TestCase

  def test_random
    assert_equal(::GlobeGlitter::random.version, 4)
    assert_equal(::GlobeGlitter::random.variant, 1)
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
    assert_nil(::GlobeGlitter::try_convert(1 << 33, 1 << 17, i << 49))
  end

  #def to_a
  #https://learn.microsoft.com/en-us/dotnet/api/system.guid.tobytearray#examples

end
