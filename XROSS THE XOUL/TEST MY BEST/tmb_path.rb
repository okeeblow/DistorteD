require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/xross-the-xoul/path') unless defined?(::XROSS::THE::PATH)

class TestXrossDesktop < ::Test::Unit::TestCase

  def test_data_dirs
    assert_not_empty(::XROSS::THE::PATH.data_dirs)
    assert_true(::XROSS::THE::PATH.data_dirs.all? { _1.is_a?(::Pathname) })
  end

end
