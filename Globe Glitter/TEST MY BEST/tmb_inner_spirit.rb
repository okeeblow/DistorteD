require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitterInnerSpirit < Test::Unit::TestCase

  def test_version
    ::GlobeGlitter::nil.tap { |gg|
      assert_equal(gg.version, 0)
      gg.version = 1
      assert_equal(gg.version, 1)
      gg.version = 2
      assert_equal(gg.version, 2)
      gg.version = 3
      assert_equal(gg.version, 3)
      assert_raise(::ArgumentError) { gg.version = 0 }
      assert_raise(::ArgumentError) { gg.version = 9 }
    }
  end

  def test_variant
    ::GlobeGlitter::nil.tap { |gg|
      assert_equal(gg.variant, 0)
      gg.variant = 1
      assert_equal(gg.variant, 1)
      gg.variant = 2
      assert_equal(gg.variant, 2)
      gg.variant = 3
      assert_equal(gg.variant, 3)
      assert_raise(::ArgumentError) { gg.variant = 4 }
    }
  end

end
