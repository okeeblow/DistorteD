require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitterInnerSpirit < Test::Unit::TestCase

  def test_hex_string_constructor_chunks
    ::GlobeGlitter::new("ffffffff-0000-0000-0000-000000000000").tap {
      assert_equal(0xFFFFFFFF, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new("00000000-ffff-0000-0000-000000000000").tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0xFFFF, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new("00000000-0000-ffff-0000-000000000000").tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0xFFFF, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new("00000000-0000-0000-ff00-000000000000").tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0xFF, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new("00000000-0000-0000-00ff-000000000000").tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0xFF, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new("00000000-0000-0000-0000-ffffffffffff").tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0xFFFFFFFFFFFF, _1.bits47–0)
    }
  end

  def test_single_integer_constructor_chunks
    ::GlobeGlitter::new(0xFFFFFFFF_00000000_00000000_00000000).tap {
      assert_equal(0xFFFFFFFF, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new(0x00000000_FFFF0000_00000000_00000000).tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0xFFFF, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new(0x00000000_0000FFFF_00000000_00000000).tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0xFFFF, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new(0X00000000_00000000_FF000000_00000000).tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0xFF, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new(0x00000000_00000000_00FF0000_00000000).tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0xFF, _1.bits55–48)
      assert_equal(0, _1.bits47–0)
    }
    ::GlobeGlitter::new(0x00000000_00000000_0000FFFF_FFFFFFFF).tap {
      assert_equal(0, _1.bits127–96)
      assert_equal(0, _1.bits95–80)
      assert_equal(0, _1.bits79–64)
      assert_equal(0, _1.bits63–56)
      assert_equal(0, _1.bits55–48)
      assert_equal(0xFFFFFFFFFFFF, _1.bits47–0)
    }
  end

  # Chunk helper methods should set their associated part of the buffer,
  # and they must *not* affect any bits outside that.
  def test_marching_chunks
    ::GlobeGlitter::new(0).tap { |gg|

      assert_equal(0, gg.bits127–96)
      gg.bits127–96 = 0xFFFFFFFF
      assert_equal(0xFFFFFFFF, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      gg.bits127–96 = 0
      assert_equal(0, gg.bits127–96)

      assert_equal(0, gg.bits95–80)
      gg.bits95–80 = 0xFFFF
      assert_equal(0, gg.bits127–96)
      assert_equal(0xFFFF, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      gg.bits95–80 = 0
      assert_equal(0, gg.bits95–80)

      assert_equal(0, gg.bits79–64)
      gg.bits79–64 = 0xFFFF
      assert_equal(0, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0xFFFF, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      gg.bits79–64 = 0
      assert_equal(0, gg.bits79–64)

      assert_equal(0, gg.bits63–56)
      gg.bits63–56 = 0xFF
      assert_equal(0, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0xFF, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      gg.bits63–56 = 0
      assert_equal(0, gg.bits63–56)

      assert_equal(0, gg.bits55–48)
      gg.bits55–48 = 0xFF
      assert_equal(0, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0xFF, gg.bits55–48)
      assert_equal(0, gg.bits47–0)
      gg.bits55–48 = 0
      assert_equal(0, gg.bits55–48)

      assert_equal(0, gg.bits47–0)
      gg.bits47–0 = 0xFFFFFFFFFFFF
      assert_equal(0, gg.bits127–96)
      assert_equal(0, gg.bits95–80)
      assert_equal(0, gg.bits79–64)
      assert_equal(0, gg.bits63–56)
      assert_equal(0, gg.bits55–48)
      assert_equal(0xFFFFFFFFFFFF, gg.bits47–0)
      gg.bits47–0 = 0
      assert_equal(0, gg.bits47–0)
    }
  end

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

  def test_bytes
    # Wikipedia https://en.wikipedia.org/wiki/Universally_unique_identifier#Encoding sez —
    # “The binary encoding of UUIDs varies between systems. Variant 1 UUIDs, nowadays the most common structure,
    #  are encoded in a big-endian format. For example, `00112233-4455-6677-8899-aabbccddeeff` is encoded as
    #  the bytes `00 11 22 33 44 55 66 77 88 99 aa bb cc dd ee ff`.”
    assert_equal(
      [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF],
      ::GlobeGlitter::new("00112233-4455-6677-8899-aabbccddeeff").bytes
    )

    # “Variant 2 UUIDs, historically used in Microsoft's COM/OLE libraries, use a little-endian format,
    #  but appear mixed-endian with the first three components of the UUID as little-endian and last two big-endian,
    #  due to the missing byte dashes when formatted as a string. For example, `00112233-4455-6677-c899-aabbccddeeff`
    #  is encoded as the bytes `33 22 11 00 55 44 77 66 88 99 aa bb cc dd ee ff`.
    #  See the section on Variants for details on why the '88' byte becomes 'c8' in Variant 2.”
    #assert_equal(
    #  [0x33, 0x22, 0x11, 0x00, 0x55, 0x44, 0x77, 0x66, 0x88, 0x99, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF],
    #  ::GlobeGlitter::new("00112233-4455-6677-8899-aabbccddeeff", structure: ::GlobeGlitter::STRUCTURE_MICROSOFT).bytes
    #)

    # Example values from https://learn.microsoft.com/en-us/dotnet/api/system.guid.tobytearray#examples
    #assert_equal(
    #  [0xC9, 0x8B, 0x91, 0x35, 0x6D, 0x19, 0xEA, 0x40, 0x97, 0x79, 0x88, 0x9D, 0x79, 0xB7, 0x53, 0xF0],
    #  ::GlobeGlitter::new("35918bc9-196d-40ea-9779-889d79b753f0", structure: ::GlobeGlitter::STRUCTURE_MICROSOFT).bytes
    #)
  end

end
