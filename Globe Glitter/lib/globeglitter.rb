require('securerandom') unless defined?(::SecureRandom)

require('xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)


# Apollo AEGIS UID:
# - https://dl.acm.org/doi/pdf/10.1145/800220.806679  (1982)
# - https://utzoo.superglobalmegacorp.com/usenet/news084f1/b105/comp/unix/wizards/11047.txt
# - AEGIS & Domain/OS 1997 date bug http://web.mit.edu/kolya/www/csa-faq.html#4.25
# - http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=61
# - http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=79
#
# Apollo NCS:
# - https://jim.rees.org/apollo-archive/papers/ncs.pdf.gz
# - https://bitsavers.org/pdf/apollo/014962-A00_Domain_OS_Design_Principles_Jan89.pdf
# - https://stuff.mit.edu/afs/athena/astaff/project/opssrc/quotasrc/src/ncs/nck/uuid.c
# - https://utzoo.superglobalmegacorp.com/usenet/b173/comp/object/1506.txt
# - https://techpubs.jurassic.nl/manuals/0530/admin/NetLS_AG/sgi_html/ch07.html#id75980
# - https://utzoo.superglobalmegacorp.com/usenet/b176/comp/sys/apollo/6124.txt
# - https://utzoo.superglobalmegacorp.com/usenet/b176/comp/sys/apollo/6151.txt
# - https://utzoo.superglobalmegacorp.com/usenet/news068f1/b88/comp/os/research/189.txt
# - https://utzoo.superglobalmegacorp.com/usenet/news084f1/b105/comp/unix/wizards/11047.txt
# - https://utzoo.superglobalmegacorp.com/usenet/b174/comp/sys/sun/11032.txt
# - https://utzoo.superglobalmegacorp.com/usenet/b179/comp/sys/apollo/6345.txt
# - https://utzoo.superglobalmegacorp.com/usenet/b229/comp/sys/sun/15342.txt
# - https://utzoo.superglobalmegacorp.com/usenet/b179/comp/protocols/misc/989.txt
# - http://www.typewritten.org/Articles/Apollo/005488-02.pdf DOMAIN System User’s Guide
# - https://web.archive.org/web/20060712084433/http://shekel.jct.ac.il/~roman/tcp-ip-lab/ibm-tutorial/3376c411.html
#
# Version 1/3/4/5, variant 1 UUID:
# - https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.667-201210-I!!PDF-E&type=items
# - https://www.ietf.org/rfc/rfc4122.txt
# - https://github.com/ietf-wg-uuidrev/rfc4122bis
#
# Version 2, variant 1 UUID:
# - https://pubs.opengroup.org/onlinepubs/9696989899/chap5.htm#tagcjh_08_02_01_01
#
#
# Other implementations for reference:
# - FreeBSD: https://github.com/freebsd/freebsd-src/blob/main/sys/kern/kern_uuid.c
# - Lunix: https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git/tree/lib/uuid/gen_uuid.c
# - Linux also: https://github.com/util-linux/util-linux/tree/master/libuuid
# - Winders: https://learn.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid
# - Boost: https://www.boost.org/doc/libs/release/libs/uuid/doc/uuid.html
# - Apple: https://developer.apple.com/documentation/foundation/uuid
# - Apple: https://opensource.apple.com/source/CF/CF-299.35/Base.subproj/uuid.c.auto.html
# - Java: https://hg.openjdk.org/jdk/jdk/file/tip/src/java.base/share/classes/java/util/UUID.java
# - .NET: https://learn.microsoft.com/en-us/dotnet/api/system.guid
# - PHP: https://uuid.ramsey.dev/en/stable/index.html
# - TianoCore EDKⅡ: https://edk2-docs.gitbook.io/edk-ii-uefi-driver-writer-s-guide/3_foundation/35_guids
# - GUID Partition Table: https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
# - LAS: https://github.com/ASPRSorg/LAS/wiki/LAS-ProjectID-Encoding-and-Representation
# - Python: https://docs.python.org/3/library/uuid.html
# - Go: https://pkg.go.dev/github.com/google/UUID
# - ReactOS: https://doxygen.reactos.org/d9/d36/psdk_2guiddef_8h_source.html
# - FreeDCE: https://github.com/dcerpc/dcerpc/tree/master/dcerpc/uuid

# NOTE: I went back to a `::Data`-wrapped integer here because `::IO::Buffer` can't (AFAICT) be shared
#       among `::Ractor`s. Even a `READ_ONLY` `::IO:Buffer` fails to be made shareable:
#
#       irb> Ractor.make_shareable(IO::Buffer::for('lmfao'))
#       <internal:ractor>:820:in `make_shareable': can not make shareable object for
#       #<IO::Buffer 0x00007f15dbfe1ed0+5 EXTERNAL READONLY SLICE> (Ractor::Error)
::GlobeGlitter = ::Data::define(:inner_spirit, :layout, :behavior) do

  # Terminology NOTE:
  #
  # `::GlobeGlitter`'s `layout` and `behavior` are broadly equivalent to ITU-T Rec. X.667's / RFC 4122's
  # `variant` and `version`, respectively. I am renaming them for two reasons:
  #
  # - because `variant` and `version` are terrible names,
  #   telling you only that something varies and not *how* or *why* it varies.
  # - because `::GlobeGlitter` implements more than just the one specification,
  #   and I prefer to avoid defining one spec in terms of another.
  #
  # TL;DR:
  # - `layout` describes the boundaries and endianness of the chunks making up a single `::GlobeGlitter`.
  # - `behavior` describe the meaning of chunks within a single `::GlobeGlitter` as well as how it should
  #   relate to other `GG` instances.

  # Default constructor arguments.
  self::LAYOUT_UNSET              = nil
  self::BEHAVIOR_UNSET            = nil

  # http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=414 sez —
  #   “A 64-bit number that is the unique "name" of any object (file, physical or logical volune,
  #    acl, directory, etc.) that lives in or is part of the Apollo file system.
  #    Certain objects, since their UIDs must be known a priori, are given "canned" UIDs.”
  # http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=61 sez —
  #   “64-bit unique name. Four 16-bit words.”
  # http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=79 sez —
  #   “36 bits — Time Since 1/1/1980, 16 millisecond units
  #    8  bits — MBZ  (called "AVAILABLE" on page 61)
  #    20 bits — Node ID”
  # On an actual AEGIS system the UID would be used as the first 64 of a 96-bit object address:
  #   http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=98
  self::LAYOUT_AEGIS              = -1

  # NCK `uuid.c` sez —
  #  “The first 48 bits are the number of 4 usec units of time that have passed since 1/1/80 0000 GMT.
  #   The next 16 bits are reserved for future use. The next 8 bits are an address family.
  #   The next 56 bits are a host ID in the form allowed by the specified address family.”
  #
  # DCE/RPC refers to these as "old" UUIDs:
  # - By presense or absense of the `1` bit in what it calls `IS_OLD_UUID`:
  #   https://github.com/dcerpc/dcerpc/blob/master/dcerpc/uuid/uuid.c#L289
  #     #define IS_OLD_UUID(uuid) (((uuid)->clock_seq_hi_and_reserved & 0xc0) != 0x80)
  # - As seen when parsing `::Strings` into UUID structs:
  #   https://github.com/dcerpc/dcerpc/blob/master/dcerpc/uuid/uuid.c#L956-L1001
  self::LAYOUT_NCA                =  0
  self::LAYOUT_NCS                =  0

  # ITU-T Rec. X.667, ISO/IEC 9834-8, and RFC 4122 are all the same standard,
  # via either the telecom world or the Internet world.
  # Many people [who?] refer to this standard by the names of the RFC draft authors, P. Leach & R. Salz.
  # - Draft: http://upnp.org/resources/draft-leach-uuids-guids-00.txt
  # - ITU: https://www.itu.int/rec/T-REC-X.667
  # - ISO: https://www.iso.org/standard/62795.html
  # - IETF: https://www.ietf.org/rfc/rfc4122.txt
  self::LAYOUT_LEACH_SALZ         =  1
  self::LAYOUT_ITU_T_REC_X_667    =  1
  self::LAYOUT_RFC_4122           =  1
  self::LAYOUT_ISO_9834_8         =  1
  self::LAYOUT_IEC_9834_8         =  1

  # These two values correspond to the equivalent ITU-T Rec. X.667 / RFC 4122 `variant` for MS and future-reservation.
  # The `microsoft` type is awkwardly mixed-endian, and future is afaik still unused.
  self::LAYOUT_MICROSOFT          =  2
  self::LAYOUT_FUTURE             =  3

  #
  self::BEHAVIOR_TIME_APOLLO      =  0
  self::BEHAVIOR_TIME_GREGORIAN   =  1
  self::BEHAVIOR_RANDOM           =  4
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
  #       https://winprotocoldoc.blob.core.windows.net/productionwindowsarchives/MS-RPCE/%5bMS-RPCE%5d-210407.pdf sez —
  #       “globally unique identifier (GUID): A term used interchangeably with universally unique identifier (UUID)
  #        in Microsoft protocol technical documents (TDs). Interchanging the usage of these terms does not imply
  #        or require a specific algorithm or mechanism to generate the value.
  #        Specifically, the use of this term does not imply or require that the algorithms described in [RFC4122]
  #        or [C706] must be used for generating the GUID. See also universally unique identifier (UUID).”
  #       “universally unique identifier (UUID): A 128-bit value. UUIDs can be used for multiple purposes,
  #        from tagging objects with an extremely short lifetime, to reliably identifying very persistent objects in
  #        cross-process communication such as client and server interfaces, manager entry-point vectors, and RPC objects.
  #        UUIDs are highly likely to be unique. UUIDs are also known as globally unique identifiers (GUIDs)
  #        and these terms are used interchangeably in the Microsoft protocol technical documents (TDs).
  #        Interchanging the usage of these terms does not imply or require a specific algorithm or mechanism
  #        to generate the UUID. Specifically, the use of this term does not imply or require that the algorithms
  #        described in [RFC4122] or [C706] must be used for generating the UUID.”
  #
  #       https://www.mandiant.com/resources/blog/hunting-com-objects sez —
  #       “Every COM object is identified by a unique binary identifier. These 128 bit (16 byte) globally
  #        unique identifiers are generically referred to as GUIDs.  When a GUID is used to identify a COM object,
  #        it is a CLSID (class identifier), and when it is used to identify an Interface it is an IID (interface identifier).
  #        Some CLSIDs also have human-readable text equivalents called a ProgID.”
  #
  #       Laser file format describes Microsoft-style endianness: https://github.com/ASPRSorg/LAS/wiki/LAS-ProjectID-Encoding-and-Representation
  #       “LAS GUIDs as encoded in the four ProjectID fields of the LAS header are intended to follow Microsoft-style 4-2-2-2-6 UUIDs
  #        with one 4-byte unsigned integer, followed by three 2-byte unsigned integers, followed by one 6-byte unsigned integer.
  #        The first three integers are customarily encoded in Little-Endian (LE) format,
  #        while the last two integers are encoded in Big-Endian (BE) format.”
  #
  #       SMBIOS spec https://www.dmtf.org/sites/default/files/standards/documents/DSP0134_2.6.0.pdf#page=21 sez —
  #       “Although RFC 4122 recommends network byte order for all fields, the PC industry (including the ACPI, UEFI,
  #        and Microsoft specifications) has consistently used little-endian byte encoding for the first three fields:
  #        `time_low`, `time_mid`, `time_hi_and_version`. The same encoding, also known as wire format, should also
  #        be used for the SMBIOS representation of the UUID. The UUID `{00112233-4455-6677-8899-AABBCCDDEEFF}`
  #        would thus be represented as `33 22 11 00 55 44 77 66 88 99 AA BB CC DD EE FF`.
  #        If the value is all `FFh`, the ID is not currently present in the system, but can be set.
  #        If the value is all `00h`, the ID is not present in the system.”
  #
  #       These posts show examples of poor endian handling SMBIOS tools:
  #       https://ocdnix.wordpress.com/2013/02/26/fuckin-uuids/
  #       http://howtowriteaprogram.blogspot.com/2009/03/uuid-and-byte-order.html
  #       http://howtowriteaprogram.blogspot.com/2012/06/smbios-uuid-fail.html
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
  #       “Note that GUIDs and UUIDs are similar. However, EFI GUID structures observe an 8-4-4-16
  #        format in source code. UUID layouts, in contrast, observe an 8-4-4-4-12 format.”
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
  self::MATCH_AEGIS_UID    = /\A\h{1,8}[,\.]\h{1,8}\Z/
  self::MATCH_NCA_UUID     = /\A(\h{12})\.(\h\h).(\h\h).(\h\h)\.(\h\h)\.(\h\h)\.(\h\h)\.(\h\h)\.(\h\h)\Z/
  self::MATCH_GUID         = /\A\{?([0-9A-F]{8})-?([0-9A-F]{4})-?([0-9A-F]{4})-?([0-9A-F]{4})-?([0-9A-F]{12})\}?\Z/
  self::MATCH_UUID         = %r&
    # Beginning-of-String anchor
    \A
    # Optional URN and hex-String-OID preambles
    (?:(?:[oO][iI][dD]|[uU][rR][nN])(?::\/|:)[uU][uU][iI][dD](?:\/|:))?
    # Dude (Looks Like a UUID)
    ([0-9a-f]{8})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{12})
    # End-of-String anchor
    \Z
  &x
  self::MATCH_UUID_OR_GUID = %r&
    # Beginning-of-String anchor
    \A
    # Optional URN and hex-String-OID preambles
    (?:(?:oid|urn)(?::\/|:)uuid(?:\/|:))?
    # Optional GUID-style leading brace
    # TODO: Look ahead/behind to only match a pair of braces, not just one or the other
    \{?
    # Case-insensitive hex-String matches
    (\h{8})-?(\h{4})-?(\h{4})-?(\h{4})-?(\h{12})
    # Optional GUID-style trailing brace
    \}?
    # End-of-String anchor
    \Z
  &xi

  # NOTE: This is hacky because we are matching characters, not numeric ranges.
  #       irb> ::GlobeGlitter::max.to_i => 340282366920938463463374607431768211455
  #       irb> ::GlobeGlitter::max.to_i.digits.size => 39
  #
  #       We **MUST** check `#bit_length <= 128` after matching something with this,
  #       because it will match any digits of the specified length, even if they exceed `::max`.
  #
  # TOD0: Come up with an error-proof no-secondary-check-needed way to do this.
  self::MATCH_UUID_OID     = /\Aurn:oid:2.25.([0-9]{1,39})\Z/i


  # https://zverok.space/blog/2023-01-03-data-initialize.html
  def self.new(*parts, layout: self::LAYOUT_UNSET, behavior: self::BEHAVIOR_UNSET) = self::allocate.tap { |gg|
    # TODO: reject integer arguments smaller than the bit_length which would indicate variant/version
    gg.send(
      :initialize,
      inner_spirit: case parts
      in [::String => uuid_or_guid] if uuid_or_guid.match(self::MATCH_UUID_OR_GUID) then
        ::Regexp::last_match.captures.map!(&:hex).yield_self {
          # Minute differences in `::String` format can indicate intended endianness.
          # Set the `layout` flag to little-endian iff it looks like a MS-style GUID
          # (braces, uppercase hex, or known CLSID), otherwise assume it's ITU/RFC-style big-endian.
          layout = self::LAYOUT_MICROSOFT if (
            (layout.eql?(self::LAYOUT_UNSET) and uuid_or_guid.match(self::MATCH_GUID)) or
            (self::KNOWN_MICROSOFT_DATA4.include?((_1[3] << 48) | _1[4]))
          )
          layout = self::LAYOUT_ITU_T_REC_X_667 if layout.eql?(self::LAYOUT_UNSET)
          ((layout.eql?(self::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(_1[0]) : _1[0]) << 96) |
          ((layout.eql?(self::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(_1[1]) : _1[1]) << 80) |
          ((layout.eql?(self::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(_1[2]) : _1[2]) << 64) |
          (_1[3] << 48) |
           _1[4]
        }
      in [::String => oid] if (
        # Must test `#bit_length` here because our `::Regexp` is too broad and will match up to `9{39}`.
        oid.match(self::MATCH_UUID_OID) and ::Regexp::last_match&.[](1).to_i.bit_length.<=(128)
      ) then
        layout = self::LAYOUT_ITU_T_REC_X_667 if layout.eql?(self::LAYOUT_UNSET)
        ::Regexp::last_match&.[](1).to_i
      in [::Array => data] if (
        data.size.eql?(16) and data.all?(::Integer) and data.max.bit_length.<=(8)
      ) then
        data.reduce { (_1 << 8) | _2 }
      in ::Array => data if (
        # I would prefer to combine this with the bracketed case above, but alternative patterns
        # currently can't be used along with variable assignment. I tried to do it without assignment
        # and use `parts` directly but the bracketed form refused to match regardless of order v(._. )v
        data.size.eql?(16) and data.all?(::Integer) and data.max.bit_length.<=(8)
      ) then
        data.reduce { (_1 << 8) | _2 }
      in [::Integer => data1, ::Integer => data2, ::Integer => data3, ::Array => data4] if (
        data1.bit_length.<=(32) and data2.bit_length.<=(16) and data3.bit_length.<=(16) and (
          data4.size.eql?(8) and data4.all?(::Integer) and data4.max.bit_length.<=(8)
        )
      ) then
        # Assume components are little-endian from a Microsoft-style GUID.
        # The `::Array` form of `DATA4` is a way they sidestepped the endianness issue, allowing `DATA4`
        # to be *effectively* big-endian. This is why people mistakenly refer to GUIDs as "mixed-endian".
        # https://learn.microsoft.com/en-us/windows/win32/api/guiddef/ns-guiddef-guid
        layout = self::LAYOUT_MICROSOFT
        ((layout.eql?(self::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(data1) : data1) << 96) |
        ((layout.eql?(self::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(data2) : data2) << 80) |
        ((layout.eql?(self::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(data3) : data3) << 64) |
        data4.reduce { (_1 << 8) | _2 }
      in [::Integer => aegis_time, 0, ::Integer => node] if (
        aegis_time.bit_length.<=(36) and node.bit_length.<=(20) and
        layout.eql?(self::LAYOUT_AEGIS)  # This old uncommon layout must be explicitly asked for.
      ) then
        (aegis_time << 28) | node
      in [::Integer => ncs_time, 0, ::Integer => address_family, ::Integer => node] if (
        ncs_time.bit_length.<=(48) and address_family.bit_length.<=(7) and node.bit_length.<=(56) and
        layout.eql?(self::LAYOUT_NCS)  # This old uncommon layout must be explicitly asked for.
      ) then
        (ncs_time << 80) | (address_family << 56) | node
      in [::Integer => spirit] if spirit.bit_length.<=(128) then spirit
      in [::Integer => msb, ::Integer => lsb] if (
        msb.bit_length.<=(64) and lsb.bit_length.<=(64)
      ) then (msb << 64) | lsb
      in [::Integer => time, ::Integer => seq, ::Integer => node] if (
        time.bit_length.<=(64) and seq.bit_length.<=(16) and node.bit_length.<=(48)
      ) then
        (time << 64) | (seq  << 48) | node
      else raise ::ArgumentError::new("invalid number or structure of arguments")  #TOD0: "given/expected"?
      end,
      layout: (layout.respond_to?(:>=) and layout&.>=(-1)) ? layout : self::LAYOUT_UNSET,
      behavior: (behavior.respond_to?(:>=) and behavior&.>=(0)) ? behavior : self::BEHAVIOR_UNSET,
    )  # send(:initialize)
  }  # def self.new

  # Our custom `::new` handles most of this functionality already but `raise`s on mismatch.
  def self.try_convert(...) = begin; self.new(...); rescue ::ArgumentError; nil; end

  # ITU-T Rec. X.667 sez —
  # “The nil UUID is special form of UUID that is specified to have all 128 bits set to zero.”
  def self.nil = self::new(0)

  # New UUID Formats draft
  # https://www.ietf.org/archive/id/draft-peabody-dispatch-new-uuid-format-04.html#name-max-uuid sez —
  # “The Max UUID is special form of UUID that is specified to have all 128 bits set to 1.
  #  This UUID can be thought of as the inverse of Nil UUID defined in [RFC4122], Section 4.1.7”
  def self.max = self::new(0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF)

  # Generate version 4 random UUID.
  # `::SecureRandom::uuid` does this already and is built-in since Ruby 1.9, but it only provides a `::String`.
  # Our implementation with `random_number` is much faster than converting that `::String` to `::Integer`.
  def self.random = self::new(
    ::SecureRandom::random_number(0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF),  # "Maximum" 128-bit UUID
    layout: self::LAYOUT_ITU_T_REC_X_667,
    behavior: self::BEHAVIOR_RANDOM,
  )

end  # ::GlobeGlitter

# Bit-twiddling and bit-chunking components.
require_relative('globeglitter/inner_spirit') unless defined?(::GlobeGlitter::INNER_SPIRIT)
::GlobeGlitter::include(::GlobeGlitter::INNER_SPIRIT)

# `::String`-printing components.
require_relative('globeglitter/say_yeeeahh') unless defined?(::GlobeGlitter::SAY_YEEEAHH)
::GlobeGlitter::include(::GlobeGlitter::SAY_YEEEAHH)

# Microsoft-style GUID components.
require_relative('globeglitter/alien_temple') unless defined?(::GlobeGlitter::ALIEN_TEMPLE)
::GlobeGlitter::include(::GlobeGlitter::ALIEN_TEMPLE)

# Sorting components.
require_relative('globeglitter/first_resolution') unless defined?(::GlobeGlitter::FIRST_RESOLUTION)
::GlobeGlitter::include(::GlobeGlitter::FIRST_RESOLUTION)

# Time-based components for UUIDv1, UUIDv6, UUIDv7, etc.
require_relative('globeglitter/chrono_diver') unless defined?(::GlobeGlitter::CHRONO_DIVER)
::GlobeGlitter::extend(::GlobeGlitter::CHRONO_DIVER::PENDULUMS)
::GlobeGlitter::include(::GlobeGlitter::CHRONO_DIVER::FRAGMENT)

# Shared `sequence` for time-based identifiers.
require_relative('globeglitter/chrono_seeker') unless defined?(::GlobeGlitter::CHRONO_SEEKER)
