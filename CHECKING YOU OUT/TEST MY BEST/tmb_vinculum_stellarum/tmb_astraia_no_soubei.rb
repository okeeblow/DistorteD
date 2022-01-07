require('bundler/setup')
require('pathname') unless defined?(::Pathname)
require('set') unless defined?(::Set)
require('test/unit') unless defined?(::Test::Unit)

require_relative('../../lib/checking-you-out') unless defined?(::CHECKING::YOU::OUT::ASTRAIAの双皿)

class TestASTRAIAの双皿 < Test::Unit::TestCase

  def setup
    @glob1 = ::CHECKING::YOU::OUT::ASTRAIAの双皿::new("[Mm]akefile.*")
    @glob2 = ::CHECKING::YOU::OUT::ASTRAIAの双皿::new("*.zip")
    @glob3 = ::CHECKING::YOU::OUT::ASTRAIAの双皿::new("*.7z.001")
  end

  def test_charclass_eql?
    assert_equal(@glob1, "Makefile.lol")
    assert_not_equal(@glob1, "Makefile")
    assert_equal(@glob1, "makefile.lol")
    assert_not_equal(@glob1, "makefile")
  end

  def test_sinistar?
    assert_false(@glob1.sinistar?)
    assert_true(@glob2.sinistar?)
    assert_true(@glob3.sinistar?)
  end

  def test_sinistar
    assert_equal(@glob1.sinistar.to_s, @glob1)
    assert_equal(@glob2.sinistar.itself, "zip")
    assert_kind_of(::Array, @glob3.sinistar.itself)
  end

end
