require('comparable') unless defined?(::Comparable)
require('xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)

::GlobeGlitter::FIRST_RESOLUTION = ::Module::new do

  # TL;DR: This comparator works at the bit level, comparing the raw bits of each side regardless of endianness.
  #
  #
  # ITU-T Rec. X.667 sez —
  #
  # “To compare a pair of UUIDs, the values of the corresponding fields (see 6.1) of each UUID are compared,
  #  in order of significance (see 6.1.2). Two UUIDs are equal if and only if all the corresponding fields are equal.
  #
  #  NOTE 1 — This algorithm for comparing two UUIDs is equivalent to the comparison of the values of
  #           the single integer representations specified in 6.3.
  #  NOTE 2 — This comparison uses the physical fields specified in 6.1.1 not the values listed in 6.1.3
  #           and specified in clause 12 (Time, Clock Sequence, Variant, Version, and Node).
  #
  # A UUID is considered greater than another UUID if it has a larger value for the most significant field in which they differ.
  #
  # In a lexicographical ordering of the hexadecimal representation of UUIDs (see 6.4), a larger UUID shall follow a smaller UUID.”
  #
  #
  # RFC 4122 sez —
  #
  # “Rules for Lexical Equivalence:
  #  Consider each field of the UUID to be an unsigned integer as shown in the table in section Section 4.1.2.
  #  Then, to compare a pair of UUIDs, arithmetically compare the corresponding fields
  #  from each UUID in order of significance and according to their data type.
  #  Two UUIDs are equal if and only if all the corresponding fields are equal.”
  #
  # “As an implementation note, equality comparison can be performed on many systems by doing
  #  the appropriate byte-order canonicalization, and then treating the two UUIDs as 128-bit unsigned integers.”
  #
  #
  # The 1998 Leach-Salz draft sez —
  #
  # “Comparing UUIDs for equality:
  #  Consider each field of the UUID to be an unsigned integer as shown in the table in section 3.1.
  #  Then, to compare a pair of UUIDs, arithmetically compare the corresponding fields from each UUID
  #  in order of significance and according to their data type.
  #  Two UUIDs are equal if and only if all the corresponding fields are equal.”
  #
  #  “Note: as a practical matter, on many systems comparison of two UUIDs for equality can be performed simply
  #         by comparing the 128 bits of their in-memory representation considered as a 128 bit unsigned integer.
  #         Here, it is presumed that by the time the in-memory representation is obtained the appropriate
  #         byte-order canonicalizations have been carried out.”
  #
  #
  # DCE RPC sez — “lexical ordering is not temporal ordering!”
  # https://github.com/dcerpc/dcerpc/blob/master/dcerpc/uuid/uuid.c#L1152-L1305
  COMPARATOR_MEMCMP           = 1
  COMPARATOR_LEACH_SALZ       = 1
  COMPARATOR_ITU_T_REC_X_667  = 1
  COMPARATOR_RFC_4122         = 1
  COMPARATOR_ISO_9834_8       = 1
  COMPARATOR_IEC_9834_8       = 1


  # TL;DR: This comparator works by comparing the integer values (not the bit values!)
  #        of the GUID-style layout from GUID-msb to GUID-lsb,
  #        i.e. we need to care about endianness!
  #
  # DotNet `System.Guid.CompareTo` doc sez —
  #
  # “The CompareTo method compares the GUIDs as if they were values provided to
  #  the Guid(Int32, Int16, Int16, Byte[]) constructor, as follows:
  #   - It compares the UInt32 values, and returns a result if they are unequal.
  #     If they are equal, it performs the next comparison.
  #   - It compares the first UInt16 values, and returns a result if they are unequal.
  #     If they are equal, it performs the next comparison.
  #   - It compares the second UInt16 values, and returns a result if they are unequal.
  #     If they are equal, it performs the next comparison.
  #   - If performs a byte-by-byte comparison of the next eight Byte values.
  #     When it encounters the first unequal pair, it returns the result.
  #     Otherwise, it returns 0 to indicate that the two Guid values are equal.”
  COMPARATOR_DOTNET           = 2


  # `https://web.archive.org/web/20190122185434/https://blogs.msdn.microsoft.com/
  #  sqlprogrammability/2006/11/06/how-are-guids-compared-in-sql-server-2005/`
  #
  # SQL Server doc sez —
  #
  # “Given these two uniqueidentifier values:
  #    `@g1 = '55666BEE-B3A0-4BF5-81A7-86FF976E763F'`
  #    `@g2 = '8DD5BCA5-6ABE-4F73-B4B7-393AE6BBB849'`
  #
  #  Many people think that `@g1` is less than `@g2`, since `55666BEE` is certainly smaller than `8DD5BCA5`.
  #  However, this is not how SQL Server 2005 compares uniqueidentifier values.
  #
  #  The comparison is made by looking at byte "groups" right-to-left, and left-to-right within a byte "group".
  #  A byte group is what is delimited by the `-` character. More technically, we look at bytes {10 to 15} first,
  #  then {8-9}, then {6-7}, then {4-5}, and lastly {0 to 3}.
  #
  #  In this specific example, we would start by comparing `86FF976E763F` with `393AE6BBB849`.
  #  Immediately we see that `@g2` is indeed greater than `@g1`.
  #
  #  Note that in .NET languages, Guid values have a different default sort order than in SQL Server.
  #  If you find the need to order an array or list of Guid [in .NET] using SQL Server comparison semantics,
  #  you can use an array or list of `SqlGuid` instead, which implements `IComparable` in a way
  #  which is consistent with SQL Server semantics.”
  COMPARATOR_MS_SQL           = 3


  # https://learn.microsoft.com/en-us/cpp/cppcx/platform-guid-value-class
  #
  # MS Windows CPP doc sez —
  #
  # “The ordering is lexicographic after treating each `Platform::Guid` as if it's an array
  #  of four 32-bit unsigned values. This isn't the ordering used by SQL Server or the .NET Framework,
  #  nor is it the same as lexicographical ordering by string representation.”
  COMPARATOR_MS_PLATFORM_GUID = 4

  # TL;DR: This comparator works by comparing the 64 most-significant bits of each UUID,
  #        followed by the 64 least-significant bits of each UUID.
  #        The complicating factor is that we must mimic the way Java treats numeric datatypes,
  #        because those 64-bit chunks mean something different in Java-land than in Ruby-land.
  #
  # https://hg.openjdk.org/jdk/jdk/file/tip/src/java.base/share/classes/java/util/UUID.java sez —
  # “`compareTo()` — The first of two UUIDs is greater than the second if the most significant field
  #                  in which the UUIDs differ is greater for the first UUID.”
  #
  # https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html sez —
  # “long: The long data type is a 64-bit two's complement integer.
  #        The signed long has a minimum value of -2⁶³ and a maximum value of 2⁶³-1.”
  COMPARATOR_JAVA_UTIL_UUID   = 5

  # https://github.com/ruby/ruby/blob/master/compar.c
  include(::Comparable)

  # TODO: Figure out how to make comparator selection usable from the C-defined `::Comparable` methods.
  def <=>(otra, comparator: COMPARATOR_ITU_T_REC_X_667)
    case otra
    when ::GlobeGlitter then
      case comparator
      when COMPARATOR_ITU_T_REC_X_667  then self.inner_spirit.<=>(otra.inner_spirit)
      when COMPARATOR_DOTNET           then
        [self.data1, self.data2, self.data3, *self.data4].<=>(
          [otra.data1, otra.data2, otra.data3, *otra.data4]
        )
      when COMPARATOR_MS_SQL           then
        [self.bits47–0, self.bits55–48, self.bits79–64, self.bits95–80, self.bits127–96].<=>(
          [otra.bits47–0, otra.bits63–48, otra.bits79–64, otra.bits95–80, otra.bits127–96]
        )
      when COMPARATOR_MS_PLATFORM_GUID then
        # Test layout and swap here instead of using our `data{1..4}` accessors
        # because those accessors do not align to the 32-bit chunk sizes needed here.
        [
          self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(self.bits127–96) : self.bits127–96,
          self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(self.bits95–64)  : self.bits95–64,
          self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(self.bits63–32)  : self.bits63–32,
          self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(self.bits31–0)   : self.bits31–0,
        ].<=>(
          [
            otra.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(otra.bits127–96) : otra.bits127–96,
            otra.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(otra.bits95–64)  : otra.bits95–64,
            otra.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(otra.bits63–32)  : otra.bits63–32,
            otra.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(otra.bits31–0)   : otra.bits31–0,
          ]
        )
      when COMPARATOR_JAVA_UTIL_UUID   then
        # Two's-complement-to-decimal, then compare.
        [
          ((self.data1 << 32) | (self.data2 << 16) | self.data3).yield_self {
            ((_1 & ~(1 << 63)) - (_1 & (1 << 63)))
          },
          ((self.bits63–0 & ~(1 << 63)) - (self.bits63–0 & (1 << 63))),
        ].<=>(
          [
            ((otra.data1 << 32) | (otra.data2 << 16) | otra.data3).yield_self {
              ((_1 & ~(1 << 63)) - (_1 & (1 << 63)))
            },
            ((otra.bits63–0 & ~(1 << 63)) - (otra.bits63–0 & (1 << 63))),
          ]
        )
      else raise ::ArgumentError::new("unsupported comparator #{comparator}")
      end
    else nil
    end
  end  # <=>

end
