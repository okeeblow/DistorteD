require('forwardable') unless defined?(::Forwardable)
require('comparable') unless defined?(::Comparable)

::GlobeGlitter::FIRST_RESOLUTION = ::Module::new do

  # https://devblogs.microsoft.com/oldnewthing/20190426-00/?p=102450
  # https://devblogs.microsoft.com/oldnewthing/20190913-00/?p=102859
  # https://bornsql.ca/blog/how-sql-server-stores-data-types-guid/
  # https://github.com/dcerpc/dcerpc/blob/master/dcerpc/uuid/uuid.c#L1203

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
  COMPARATOR_LEACH_SALZ         =  1
  COMPARATOR_ITU_T_REC_X_667    =  1
  COMPARATOR_RFC_4122           =  1
  COMPARATOR_ISO_9834_8         =  1
  COMPARATOR_IEC_9834_8         =  1

  include(::Comparable)
  def <=>(otra, comparator: COMPARATOR_ITU_T_REC_X_667)
    case otra
    when ::GlobeGlitter then
      case comparator
      when COMPARATOR_ITU_T_REC_X_667 then self.inner_spirit.<=>(otra.inner_spirit)
      else raise ::ArgumentError::new("unsupported comparator #{comparator}")
      end
    else self.<=>(::GlobeGlitter::try_convert(otra))
    end
  end
end
