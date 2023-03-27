require('securerandom') unless defined?(::SecureRandom)
require('xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)


# TODO: Convert to `Data` in Ruby 3.2
#
# Apollo AEGIS UID:
# - https://dl.acm.org/doi/pdf/10.1145/800220.806679  (1982)
#
# Apollo NCS:
# - https://jim.rees.org/apollo-archive/papers/ncs.pdf.gz
# - https://bitsavers.org/pdf/apollo/014962-A00_Domain_OS_Design_Principles_Jan89.pdf
#
# Version 1/3/4/5, variant 1 UUID:
# - https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.667-201210-I!!PDF-E&type=items
# - https://www.ietf.org/rfc/rfc4122.txt
#
# Version 2, variant 1 UUID:
# - https://pubs.opengroup.org/onlinepubs/9696989899/chap5.htm#tagcjh_08_02_01_01
#
#
# Other implementations for reference:
# - FreeBSD: https://github.com/freebsd/freebsd-src/blob/main/sys/kern/kern_uuid.c
# - Lunix: https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/tree/lib/uuid/gen_uuid.c
# - Winders: https://learn.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid
# - Boost: https://www.boost.org/doc/libs/1_81_0/libs/uuid/doc/uuid.html
# - Apple: https://developer.apple.com/documentation/foundation/uuid
# - Apple: https://opensource.apple.com/source/CF/CF-299.35/Base.subproj/uuid.c.auto.html
# - Java: https://docs.oracle.com/en/java/javase/19/docs/api/java.base/java/util/UUID.html
# - .NET: https://learn.microsoft.com/en-us/dotnet/api/system.guid
# - PHP: https://uuid.ramsey.dev/en/stable/index.html
::GlobeGlitter = ::Struct::new(:inner_spirit) do

  self::VARIANT_UNSET           = -1
  self::VARIANT_NCS             =  0
  self::VARIANT_LEACH_SALZ      =  1
  self::VARIANT_ITU_T_REC_X_667 =  1
  self::VARIANT_RFC_4122        =  1
  self::VARIANT_MICROSOFT       =  2
  self::VARIANT_FUTURE          =  3

  self::VERSION_UNSET           = -1
  self::VERSION_TIME            =  1
  self::VERSION_RANDOM          =  4
  # TODO: Versions 2–8 (WIP)

  # NOTE: I am adopting two conventions here which are ***not*** part of any specification despite their wide use!
  #
  #       Within this library, usage of the term "GUID" (versus "UUID") and usage of upper-case hexadecimal `A-F`
  #       indicate Microsoft-style mixed-endianness, i.e. the `time` bits are little-endian while the `clock_seq`
  #       and `node` bits are big/network-endian, represented in Windows-land as an `Array` of bytes, e.g.:
  #       https://learn.microsoft.com/en-us/windows/win32/wic/-wic-guids-clsids
  #
  #       My support of the GUID/UUID differentiation convention is based on the fact that ITU-T Rec X.667 does not
  #       contain a single instance of the term "GUID". RFC 4122, on the other hand, sez:
  #       “Uniform Resource Name namespace for UUIDs (Universally Unique IDentifier),
  #        also known as GUIDs (Globally Unique IDentifier).”
  #
  #       GG will store GUIDs internally in the network byte order, and our `#<=>` method will handle the opposite
  #       sortability implications, RE: https://devblogs.microsoft.com/oldnewthing/20190426-00/?p=102450
  #
  #       The upper-case-hex GUID convention is a Microsoft thing, not part of the ITU/RFC UUID spec:
  #       https://learn.microsoft.com/en-us/windows/win32/msi/guid  “All GUIDs must be authored in uppercase.”
  #
  #       Correspondingly, ITU-T Rec. X.667 sez,
  #       “Software generating the hexadecimal representation of a UUID shall not use upper case letters.”
  #
  #       Our third match condition allows mixed-case, because we have to contend with nonconforming software,
  #       with hand-authored input by people unfamiliar with those conventions, etc. We will treat these as UUID.
  self::MATCH_GUID         = /\A\{?([0-9A-F]{8})-?([0-9A-F]{4})-?([0-9A-F]{4})-?([0-9A-F]{4})-?([0-9A-F]{12})\}?\Z/
  self::MATCH_UUID         = /\A\{?([0-9a-f]{8})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{12})\}?\Z/
  self::MATCH_UUID_OR_GUID = /\A\{?(\h{8})-?(\h{4})-?(\h{4})-?(\h{4})-?(\h{12})\}?\Z/

  def self.new(*parts, variant: self::VARIANT_ITU_T_REC_X_667, version: self::VERSION_UNSET)
    self::allocate.tap { |gg|
      gg.send(
        :initialize,
        case parts
          in [::String => probably_uuid] if probably_uuid.match(self::MATCH_UUID) then
            ::Regexp::last_match.captures.map!(&:hex).yield_self {
              (_1[0] << 96) | (_1[1] << 80) | (_1[2] << 64) | (_1[3] << 48) | (_1[4])
            }
          in [::String => probably_guid] if probably_guid.match(self::MATCH_GUID) then
            ::Regexp::last_match.captures.map!(&:hex).yield_self {
              (::XROSS::THE::CPU::swap32(_1[0]) << 96) |
              (::XROSS::THE::CPU::swap16(_1[1]) << 80) |
              (::XROSS::THE::CPU::swap16(_1[2]) << 64) |
              (_1[3] << 48)                            |
              (_1[4])
            }
          in [::String => either_or] if either_or.match(self::MATCH_UUID_OR_GUID) then
            ::Regexp::last_match.captures.map!(&:hex).yield_self {
              (_1[0] << 96) | (_1[1] << 80) | (_1[2] << 64) | (_1[3] << 48) | (_1[4])
            }
          in [::Integer => spirit] if spirit.bit_length.<=(128) then spirit
          in [::Integer => msb, ::Integer => lsb] if (
            msb.bit_length.<=(64) and lsb.bit_length.<=(64)
          ) then ((msb << 64) | lsb)
          in [::Integer => time, ::Integer => seq, ::Integer => node] if (
            time.bit_length.<=(64) and seq.bit_length.<=(16) and node.bit_length.<=(48)
          ) then ((time << 64) | (seq << 48) | node)
          else raise ::ArgumentError::new("invalid number or structure of arguments")  #TOD0: "given/expected"?
        end
      )
      gg.send(:variant=, variant) if variant.respond_to?(:>=) and variant&.>=(0) and not gg.eql?(0)
      gg.send(:version=, version) if version.respond_to?(:>=) and version&.>=(0)
    }
  end

  # Our custom `::new` handles most of this functionality already but `raise`s on mismatch.
  def self.try_convert(...) = begin; self.new(...); rescue ::ArgumentError; nil; end

  # ITU-T Rec. X.667 sez —
  #
  # “The nil UUID is special form of UUID that is specified to have all 128 bits set to zero.”
  def self.nil = self::new(0)

  # Generate version 4 random UUID.
  # `::SecureRandom::uuid` does this already and is built-in,
  # but that only provides a `::String` representation and ours is much faster.
  def self.random = self::new(
    ::SecureRandom::random_number(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF),
    variant: self::VARIANT_ITU_T_REC_X_667,
    version: self::VERSION_RANDOM,
  )

end  # ::GlobeGlitter

require_relative('globeglitter/inner_spirit') unless defined?(::GlobeGlitter::INNER_SPIRIT)
::GlobeGlitter::include(::GlobeGlitter::INNER_SPIRIT)

require_relative('globeglitter/say_yeeeahh') unless defined?(::GlobeGlitter::SAY_YEEEAHH)
::GlobeGlitter::include(::GlobeGlitter::SAY_YEEEAHH)

require_relative('globeglitter/chrono_diver') unless defined?(::GlobeGlitter::CHRONO_DIVER)
::GlobeGlitter::extend(::GlobeGlitter::CHRONO_DIVER::PENDULUMS)
::GlobeGlitter::include(::GlobeGlitter::CHRONO_DIVER::FRAGMENT)
