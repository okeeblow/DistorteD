require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/xross-the-xoul/os') unless defined?(::XROSS::THE::OS)

class TestXrossOS < ::Test::Unit::TestCase

  def test_chain
    assert_not_nil(::XROSS::THE::OS::CHAIN)
  end

end
