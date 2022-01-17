require('bundler/setup')
require('pathname') unless defined?(::Pathname)
require('set') unless defined?(::Set)
require('test/unit') unless defined?(::Test::Unit)

require_relative('../../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT::StellaSinistra)

class TestStellaSinistra < Test::Unit::TestCase

  def setup
    # NOTE: Multi-extname Globs will be decomposed to Glob-style individual extnames
    #       complete with '*.' prefix.
    @seven_zed = ::CHECKING::YOU::OUT::StellaSinistra["*.001", "*.7z"]
  end

  def test_from_string
    assert_equal(@seven_zed, ::CHECKING::YOU::OUT::StellaSinistra::from_string("*.7z.001"))
    assert_raise(::ArgumentError) do
      ::CHECKING::YOU::OUT::StellaSinistra::from_string("Not a valid glob lmao")
    end
  end

  def test_to_glob
    assert_equal("*.7z.001", @seven_zed.to_glob)
  end

  def test_sinistar
    assert_true(@seven_zed.sinistar?)
    assert_equal(@seven_zed, @seven_zed.sinistar)
  end

end
