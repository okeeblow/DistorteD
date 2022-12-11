require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitter < Test::Unit::TestCase

  def test_random_version
    assert_equal(::GlobeGlitter::random.version, 4)
  end

end
