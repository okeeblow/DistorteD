require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/globeglitter') unless defined?(::GlobeGlitter)

class TestGlobeGlitterSayYeeeahh < Test::Unit::TestCase

  # These are not tests for GloveGlitter code directly but are here to validate
  # decisions made during its development.
  # That is, if Ruby stdlib behavior changes, we should change with it.
  def test_assumptions
    # `::GlobeGlitter#to_s` emits `::Encoding::US_ASCII` like stdlib classes.
    assert_equal(::Encoding::US_ASCII, 333.to_s.encoding)
    assert_equal(::Encoding::US_ASCII, 333.to_f.to_s.encoding)
    assert_equal(::Encoding::US_ASCII, 69.420.to_s.encoding)
    assert_equal(::Encoding::US_ASCII, ::Time::now.to_s.encoding)
    assert_equal(333.to_s.encoding, ::GlobeGlitter::random.to_s.encoding)
    assert_equal(333.to_f.to_s.encoding, ::GlobeGlitter::random.to_s.encoding)
    assert_equal(69.420.to_s.encoding, ::GlobeGlitter::random.to_s.encoding)
    assert_equal(::Time::now.to_s.encoding, ::GlobeGlitter::random.to_s.encoding)
  end

  def test_to_oid
    # ITU-T Rec. X.667 sez —
    # “An alternative URN format [alternative to `"urn:uuid:<hex-string>"`] is available,
    #  but is not recommended for URNs generated using UUIDs.
    #  This alternative format uses the single integer value of the UUID, and represents the UUID
    #  `f81d4fae-7dec-11d0-a765-00a0c91e6bf6` as `urn:oid:2.25.329800735698586629295641978511506172918`.”
    assert_equal(
      ::String::new("urn:oid:2.25.329800735698586629295641978511506172918", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("f81d4fae-7dec-11d0-a765-00a0c91e6bf6").to_oid,
    )
    assert_equal(
      ::String::new("urn:oid:2.25.329800735698586629295641978511506172918", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("urn:oid:2.25.329800735698586629295641978511506172918").to_oid,
    )
    111.times {
      ::GlobeGlitter::random.tap {
        assert_equal(_1.to_s, ::GlobeGlitter::new(_1.to_oid).to_s)
        assert_equal(_1.to_oid, ::GlobeGlitter::new(_1.to_s).to_oid)
      }
    }
    # Must *not* match input where OID value is greater than "max UUID".
    assert_nil(::GlobeGlitter::try_convert("urn:oid:2.25.999999999999999999999999999999999999999"))
  end

  # ITU-T Rec. X.667 sez —
  # “A UUID can be used as the primary integer value of a Joint UUID arc using the single integer value of the UUID.
  #  The hexadecimal representation of the UUID can also be used as a non-integer Unicode label for the arc.
  #  EXAMPLE — The following is an example of the use of a UUID to form an IRI/URI value: 
  #            "oid:/UUID/f81d4fae-7dec-11d0-a765-00a0c91e6bf6"”
  def test_to_oid_s
    assert_equal(
      ::String::new("oid:/UUID/f81d4fae-7dec-11d0-a765-00a0c91e6bf6", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("f81d4fae-7dec-11d0-a765-00a0c91e6bf6").to_oid_s,
    )
    assert_equal(
      ::String::new("oid:/UUID/f81d4fae-7dec-11d0-a765-00a0c91e6bf6", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("oid:/UUID/f81d4fae-7dec-11d0-a765-00a0c91e6bf6").to_oid_s,
    )
    111.times {
      ::GlobeGlitter::random.tap {
        assert_equal(_1.to_s, ::GlobeGlitter::new(_1.to_oid_s).to_s)
        assert_equal(_1.to_oid_s, ::GlobeGlitter::new(_1.to_s).to_oid_s)
      }
    }
  end

  # ITU-T Rec. X.667 sez —
  # “The string representation of a UUID is fully compatible with the URN syntax.
  #  When converting from a bit-oriented, in-memory representation of a UUID into a URN,
  #  care must be taken to strictly adhere to the byte order issues
  #  mentioned in the string representation section.”
  # “The following is an example of the string representation of a UUID as a URN:
  #   urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6”
  def test_to_urn
    assert_equal(
      ::String::new("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6").to_urn,
    )
    assert_equal(
      ::String::new("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6").to_urn,
    )
    111.times {
      ::GlobeGlitter::random.tap {
        assert_equal(_1.to_s, ::GlobeGlitter::new(_1.to_urn).to_s)
        assert_equal(_1.to_urn, ::GlobeGlitter::new(_1.to_s).to_urn)
      }
    }
  end


  # UEFI GUID bytes + strings https://github.com/jethrogb/uefireverse/blob/master/guiddb/efi_guid.c
  def test_microsoft_style_guids
    # Example bytes from https://uefi.org/sites/default/files/resources/UEFI_Spec_2_10_Aug29.pdf#page=409
    assert_equal(
      ::String::new("18a031ab-b443-4d1a-a5c0-0c09261e9f71", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::try_convert(0x18a031ab, 0xb443, 0x4d1a, [0xa5, 0xc0, 0xc, 0x9, 0x26, 0x1e, 0x9f, 0x71]).to_s,
    )
    assert_equal(
      ::String::new("{18A031AB-B443-4D1A-A5C0-0C09261E9F71}", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::try_convert(0x18a031ab, 0xb443, 0x4d1a, [0xa5, 0xc0, 0xc, 0x9, 0x26, 0x1e, 0x9f, 0x71]).to_guid,
    )
    assert_equal(
      ::String::new("00112233-4455-6677-8899-aabbccddeeff", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("00112233-4455-6677-8899-aabbccddeeff", layout: ::GlobeGlitter::LAYOUT_MICROSOFT).to_s,
    )
    assert_equal(
      ::String::new("{00112233-4455-6677-8899-AABBCCDDEEFF}", encoding: ::Encoding::US_ASCII),
      ::GlobeGlitter::new("00112233-4455-6677-8899-aabbccddeeff", layout: ::GlobeGlitter::LAYOUT_MICROSOFT).to_guid,
    )
    efi_system = ::GlobeGlitter::new(::String::new("c12a7328-f81f-11d2-ba4b-00a0c93ec93b", encoding: Encoding::US_ASCII))
    assert_equal(::String::new("c12a7328-f81f-11d2-ba4b-00a0c93ec93b", encoding: Encoding::US_ASCII), efi_system.to_s)
    assert_equal(::String::new("{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}", encoding: Encoding::US_ASCII), efi_system.to_guid)
  end

end
