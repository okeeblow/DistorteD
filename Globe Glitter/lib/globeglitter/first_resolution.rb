require('forwardable') unless defined?(::Forwardable)
require('comparable') unless defined?(::Comparable)

::GlobeGlitter::FIRST_RESOLUTION = ::Module::new do

  # https://devblogs.microsoft.com/oldnewthing/20190426-00/?p=102450
  # https://devblogs.microsoft.com/oldnewthing/20190913-00/?p=102859
  # https://bornsql.ca/blog/how-sql-server-stores-data-types-guid/
  # https://github.com/dcerpc/dcerpc/blob/master/dcerpc/uuid/uuid.c#L1203

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

  # https://github.com/ruby/ruby/blob/master/compar.c
  include(::Comparable)

  # TODO: Figure out how to make comparator selection usable from the C-defined `::Comparable` methods.
  def <=>(otra, comparator: COMPARATOR_ITU_T_REC_X_667)
    case otra
    when ::GlobeGlitter then
      case comparator
      when COMPARATOR_ITU_T_REC_X_667 then self.inner_spirit.<=>(otra.inner_spirit)
      when COMPARATOR_DOTNET          then
        [self.data1, self.data2, self.data3, *self.data4].<=>(
          [otra.data1, otra.data2, otra.data3, *otra.data4]
        )
      else raise ::ArgumentError::new("unsupported comparator #{comparator}")
      end
    else self.<=>(::GlobeGlitter::try_convert(otra), comparator:)
    end
  end
end
