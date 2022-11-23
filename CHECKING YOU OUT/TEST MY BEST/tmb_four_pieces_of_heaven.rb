require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require('pathname') unless defined?(::Pathname)
require('set') unless defined?(::Set)
require_relative('../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT)

class TestFourPiecesOfHeaven < Test::Unit::TestCase

  def test_four_leaf_to_s
    # TODO: Implement `FourLeaf#to_s`/`#to_i`
    #assert_equal(::CHECKING::YOU::OUT::Miracle4::FourLeaf::new(0x6D730055).to_s, "ms\x00U")
  end

end
