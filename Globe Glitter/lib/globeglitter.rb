require('securerandom') unless defined?(::SecureRandom)
require('xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)


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
# - TianoCore EDKⅡ: https://edk2-docs.gitbook.io/edk-ii-uefi-driver-writer-s-guide/3_foundation/35_guids
# - GUID Partition Table: https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
# - LAS: https://github.com/ASPRSorg/LAS/wiki/LAS-ProjectID-Encoding-and-Representation
::GlobeGlitter = ::Data::define(:inner_spirit, :rules, :structure) do

  self::STRUCTURE_UNSET           = -1
  self::STRUCTURE_NCS             =  0
  self::STRUCTURE_LEACH_SALZ      =  1
  self::STRUCTURE_ITU_T_REC_X_667 =  1
  self::STRUCTURE_RFC_4122        =  1
  self::STRUCTURE_MICROSOFT       =  2
  self::STRUCTURE_FUTURE          =  3

  self::RULES_UNSET               = -1
  self::RULES_TIME                =  1
  self::RULES_RANDOM              =  4
  # TODO: Versions 2–8 (WIP)

  # NOTE: I am adopting two conventions here which are ***not*** explicitly part of any specification
  #       as a compromise between two mostly-compatible widely-used conventions!
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
  #       The upper-case-hex GUID convention is an old-Microsoft thing, not part of the ITU/RFC UUID spec:
  #       https://learn.microsoft.com/en-us/windows/win32/msi/guid  “All GUIDs must be authored in uppercase.”
  #
  #       https://learn.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid sez —
  #       “A GUID is a 128-bit value consisting of one group of 8 hexadecimal digits, followed by three groups
  #        of 4 hexadecimal digits each, followed by one group of 12 hexadecimal digits. The following example GUID
  #        shows the groupings of hexadecimal digits in a GUID: `6B29FC40-CA47-1067-B31D-00DD010662DA`.”
  #       `typedef struct _GUID { unsigned long  Data1; unsigned short Data2; unsigned short Data3; unsigned char Data4[8]; } GUID;`
  #       “The first 2 bytes [of `Data4`] contain the third group of 4 hexadecimal digits.
  #        The remaining 6 bytes contain the final 12 hexadecimal digits.”
  #
  #       Laser file format describes Microsoft-style endianness: https://github.com/ASPRSorg/LAS/wiki/LAS-ProjectID-Encoding-and-Representation
  #       “LAS GUIDs as encoded in the four ProjectID fields of the LAS header are intended to follow Microsoft-style 4-2-2-2-6 UUIDs
  #        with one 4-byte unsigned integer, followed by three 2-byte unsigned integers, followed by one 6-byte unsigned integer.
  #        The first three integers are customarily encoded in Little-Endian (LE) format,
  #        while the last two integers are encoded in Big-Endian (BE) format.”
  #
  #       New-Microsoft seem to use lower-case hex indiscriminately despite still calling them GUIDs,
  #       e.g. https://learn.microsoft.com/en-us/windows/win32/api/winioctl/ns-winioctl-partition_information_gpt
  #
  #       Correspondingly, ITU-T Rec. X.667 sez,
  #       “Software generating the hexadecimal representation of a UUID shall not use upper case letters.”
  #
  #       EFI specification https://stuff.mit.edu/afs/sipb/contrib/doc/EFI/EFISpec_v102.pdf#page=35
  #       and UEFI specification https://uefi.org/sites/default/files/resources/UEFI_Spec_2_10_Aug29.pdf#page=105 say —
  #       “`EFI_GUID` — 128-bit buffer containing a unique identifier value. Unless otherwise specified, aligned on a 64-bit boundary.”
  #       `typedef struct { UINT32 Data1; UINT16 Data2; UINT16 Data3; UINT8 Data4[8]; } EFI_GUID;`
  #
  #       National Security Agency UEFI Secure Boot Customization Cybersecurity Technical Report
  #       https://media.defense.gov/2020/Sep/15/2002497594/-1/-1/0/CTR-UEFI-Secure-Boot-Customization-UOO168873-20.PDF#page=18 sez —
  #       “Note that GUIDs and UUIDs are similar. However, EFI GUID ruless observe an 8-4-4-16
  #        format in source code. UUID ruless, in contrast, observe an 8-4-4-4-12 format.”
  #
  #       UEFI 2.0 errata https://uefi.org/sites/default/files/resources/UEFI_Spec_Errata_Only.pdf sez —
  #       “Add clarification to the spec so that we avoid references to GUIDs that do not comply to the
  #        <32bit><16bit><16bit><byte><byte><byte><byte><byte><byte><byte><byte> format.”,
  #       indicating use of Microsoft-style endianness.
  #
  #       Our third match condition allows mixed-case, because we have to contend with nonconforming software,
  #       with hand-authored input by people unfamiliar with those conventions, etc. We will treat these as UUID.
  #
  #       When asked to emit a "GUID", GlobeGlitter will produce upper-case.
  #       By default (e.g. `#to_s`) — and when asked to emit a "UUID", GlobeGlitter will produce lower-case.
  #
  #
  # MAYBE: Should we assume any bracketed string is a GUID regardless of hex case?
  #        Search for counter-examples in the form of bracketed-UUIDs to decide.
  self::MATCH_GUID         = /\A\{?([0-9A-F]{8})-?([0-9A-F]{4})-?([0-9A-F]{4})-?([0-9A-F]{4})-?([0-9A-F]{12})\}?\Z/
  self::MATCH_UUID         = /\A\{?([0-9a-f]{8})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{12})\}?\Z/
  self::MATCH_UUID_OR_GUID = /\A\{?(\h{8})-?(\h{4})-?(\h{4})-?(\h{4})-?(\h{12})\}?\Z/

  # https://zverok.space/blog/2023-01-03-data-initialize.html
  def self.new(*parts, structure: self::STRUCTURE_UNSET, rules: self::RULES_UNSET) = self::allocate.tap { |gg|
    gg.send(
      :initialize,
      **{
        :inner_spirit => case parts
          in [::String => probably_guid] if probably_guid.match(self::MATCH_GUID) then
            # NOTE: This *must* come before `MATCH_UUID`.
            ::Regexp::last_match.captures.map!(&:hex).yield_self {
              (::XROSS::THE::CPU::swap32(_1[0]) << 96) |
              (::XROSS::THE::CPU::swap16(_1[1]) << 80) |
              (::XROSS::THE::CPU::swap16(_1[2]) << 64) |
              (_1[3] << 48)                            |
              (_1[4])
            }
          in [::String => either_or] if (
            either_or.match(self::MATCH_UUID) or either_or.match(self::MATCH_UUID_OR_GUID)
          ) then
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
          else raise ::ArgumentError::new("invalid number or rules of arguments")  #TOD0: "given/expected"?
        end,
        :structure => (structure.respond_to?(:>=) and structure&.>=(0)) ? structure : self::STRUCTURE_UNSET,
        :rules => (rules.respond_to?(:>=) and rules&.>=(1)) ? rules : self::RULES_UNSET
      }
    )
  }

  # Our custom `::new` handles most of this functionality already but `raise`s on mismatch.
  def self.try_convert(...) = begin; self.new(...); rescue ::ArgumentError; nil; end

  # ITU-T Rec. X.667 sez —
  #
  # “The nil UUID is special form of UUID that is specified to have all 128 bits set to zero.”
  def self.nil = self::new(0)

  # Generate version 4 random UUID.
  # `::SecureRandom::uuid` does this already and is built-in since Ruby 1.9, but it only provides a `::String`.
  # Our implementation with `random_number` is much faster than converting that `::String` to `::Integer`.
  def self.random = self::new(
    ::SecureRandom::random_number(0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF),  # "Maximum" 128-bit UUID
    structure: self::STRUCTURE_ITU_T_REC_X_667,
    rules: self::RULES_RANDOM,
  )

end  # ::GlobeGlitter

require_relative('globeglitter/inner_spirit') unless defined?(::GlobeGlitter::INNER_SPIRIT)
::GlobeGlitter::include(::GlobeGlitter::INNER_SPIRIT)

require_relative('globeglitter/say_yeeeahh') unless defined?(::GlobeGlitter::SAY_YEEEAHH)
::GlobeGlitter::include(::GlobeGlitter::SAY_YEEEAHH)

require_relative('globeglitter/chrono_diver') unless defined?(::GlobeGlitter::CHRONO_DIVER)
::GlobeGlitter::extend(::GlobeGlitter::CHRONO_DIVER::PENDULUMS)
::GlobeGlitter::include(::GlobeGlitter::CHRONO_DIVER::FRAGMENT)
