require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitterInnerSpirit < Test::Unit::TestCase

  def test_rules
    ::GlobeGlitter::nil.tap { |gg|
      assert_equal(gg.rules, ::GlobeGlitter::RULES_UNSET)
      #assert_equal(::GlobeGlitter::RULES_TIME_GREGORIAN, gg.rules=(::GlobeGlitter::RULES_TIME_GREGORIAN).rules)
      #assert_equal(::GlobeGlitter::RULES_RANDOM, gg.rules=(::GlobeGlitter::RULES_RANDOM).rules)
      assert_raise(::ArgumentError) { gg.rules = 0 }
      assert_raise(::ArgumentError) { gg.rules = 9 }
    }
  end

  def test_structure
    ::GlobeGlitter::nil.tap { |gg|
      assert_equal(::GlobeGlitter::STRUCTURE_UNSET, gg.structure)
      #assert_equal(::GlobeGlitter::STRUCTURE_ITU_T_REC_X_667, gg.structure=(::GlobeGlitter::STRUCTURE_ITU_T_REC_X_667).structure)
      #assert_equal(::GlobeGlitter::STRUCTURE_MICROSOFT, gg.structure=(::GlobeGlitter::STRUCTURE_MICROSOFT).structure)
      #assert_equal(::GlobeGlitter::STRUCTURE_FUTURE, gg.structure=(::GlobeGlitter::STRUCTURE_FUTURE).structure)
      assert_raise(::ArgumentError) { gg.structure = 4 }
    }
  end

end
