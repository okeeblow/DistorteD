require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/xross-the-xoul/desktop') unless defined?(::XROSS::THE::DESKTOP)

class TestXrossDesktop < ::Test::Unit::TestCase

  def test_data_dirs
    assert_not_empty(::XROSS::THE::DESKTOP.DATA_DIRS)
    assert_true(::XROSS::THE::DESKTOP.DATA_DIRS.all? { _1.is_a?(::Pathname) })
  end

end
