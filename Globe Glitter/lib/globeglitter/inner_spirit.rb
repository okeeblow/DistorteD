# Bitslicing components.
module ::GlobeGlitter::INNER_SPIRIT

  # TODO: Rename these something more generic since the current names are very specific to the time-based UUID spec.
  #       See https://edk2-docs.gitbook.io/edk-ii-uefi-driver-writer-s-guide/3_foundation/35_guids for non-time-UUID example.

  # Getters for fields defined in the specification.
  def time_low                    =   self.inner_spirit >> 96
  def time_mid                    =  (self.inner_spirit >> 80) & 0xFFFF
  def time_high_and_version       =  (self.inner_spirit >> 64) & 0xFFFF
  def clock_seq_high_and_reserved = ((self.inner_spirit >> 56) & 0xFF) & case self.structure
    when 0    then 0b01111111
    when 1    then 0b00111111
    when 2, 3 then 0b00011111
    else           0b11111111  # Non-UUID-rules
  end
  def clock_seq_low               =  (self.inner_spirit >> 48) & 0xFF
  def node                        =   self.inner_spirit        & 0xFFFFFFFFFFFF

  # Setters for fields defined in the specification.
  def time_low=(otra)
    self.with(inner_spirit: ((otra << 96) | (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_FFFFFFFF)))
  end
  def time_mid=(otra)
    self.with(inner_spirit: (
      (self.inner_spirit & 0xFFFFFFFF_0000FFFF_FFFFFFFF_FFFFFFFF) | otra
    ))
  end
  def time_high=(otra)
    self.with(inner_spirit: (
      (self.inner_spirit & 0xFFFFFFFF_FFFFF000_FFFFFFFF_FFFFFFFF) | (otra & 0x0FFF)
    ))
  end
  def time=(otra)
    self.with(inner_spirit: (
      (self.inner_spirit & 0x00000000_0000F000_FFFFFFFF_FFFFFFFF) | ((otra & 0xFFFFFFFF_FFFF0FFF) << 64)
    ))
  end
  def clock_seq_high_and_reserved=(otra)
    self.with(inner_spirit: (
      (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_00FFFFFF_FFFFFFFF) |
      (
        (
          (otra & case self.structure
            when 0    then 0b01111111
            when 1    then 0b00111111
            when 2, 3 then 0b00011111
          end) |
          (case self.structure
            when 0    then 0b00000000
            when 1    then 0b10000000
            when 2    then 0b11000000
            when 3    then 0b11100000
          end)
        ) << 56
      )
    ))
  end
  def clock_seq_low=(otra)
    self.with(inner_spirit: (
      (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_FF00FFFF_FFFFFFFF) | otra
    ))
  end
  def node=(otra)
    self.with(inner_spirit: (
      (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_FFFF0000_00000000) | otra
    ))
  end

  # Getter for Base-16 `::String` output where these two fields are combined.
  def clock_seq = (self.clock_seq_high_and_reserved << 8) | self.clock_seq_low
  def clock_seq=(otra)
    self.with(inner_spirit: (
      (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_0000FFFF_FFFFFFFF) |
      (
        case self.structure
          when 0    then 0b00000000
          when 1    then 0b10000000
          when 2    then 0b11000000
          when 3    then 0b11100000
        end << 56
      ) | (otra << 48)
    ))
  end

  # ITU-T Rec. X.667 sez —
  #
  # “The version number is in the most significant 4 bits of the time
  #  stamp (bits 4 through 7 of the time_hi_and_version field).”
  #
  # “The following table lists the currently-defined versions for this UUID structure.”
  #
  # Msb0  Msb1  Msb2  Msb3   Version  Description
  #
  #  0     0     0     1        1     The time-based version
  #                                   specified in this document.
  #
  #  0     0     1     0        2     DCE Security version, with
  #                                   embedded POSIX UIDs.
  #
  #  0     0     1     1        3     The name-based version
  #                                   specified in this document
  #                                   that uses MD5 hashing.
  #
  #  0     1     0     0        4     The randomly or pseudo-
  #                                   randomly generated version
  #                                   specified in this document.
  #
  #  0     1     0     1        5     The name-based version
  #                                   specified in this document
  #                                   that uses SHA-1 hashing.
  #
  # “The version is more accurately a sub-type; again, we retain the term for compatibility.”
  def rules = (self.inner_spirit >> 76) & 0xF
  # TODO: Convert this into `#replace` or just remove it, because assignment methods in Ruby can only return their argument.
  def rules=(otra)
    raise ::ArgumentError::new("invalid version #{otra.to_s}") unless otra.is_a?(::Integer) and otra.between?(1, 8)
    return self.with(
      inner_spirit: (self.inner_spirit & 0xFFFFFFFF_FFFF0FFF_FFFFFFFF_FFFFFFFF) | (otra << 76),
      rules: otra,
    )
  end
  # This is just straight-up the same thing as "version" in the UUID specification,
  # but I don't want to call it that because it's a terrible ambiguous word
  # for anybody unfamiliar with the minutae of the specs.
  # We should still provide it as `#version` because why not??
  alias_method(:version, :rules)

  # ITU-T Rec. X.667 sez —
  #
  # “The structure field determines the layout of the UUID.
  #  That is, the interpretation of all other bits in the UUID depends on the setting
  #  of the bits in the structure field.  As such, it could more accurately be called a type field;
  #  we retain the original term for compatibility.
  #  The structure field consists of a variable number of the most significant bits of octet 8 of the UUID.
  #
  # “The following table lists the contents of the structure field, where
  #  the letter "x" indicates a "don't-care" value.
  #
  #   Msb0  Msb1  Msb2  Description
  #
  #    0     x     x    Reserved, NCS backward compatibility.
  #
  #    1     0     x    The structure specified in this document.
  #
  #    1     1     0    Reserved, Microsoft Corporation backward compatibility
  #
  #    1     1     1    Reserved for future definition.
  #
  #
  # NOTE: Some libraries (like `java.util.UUID`) specify the structure value as if it were not backwards-masked:
  #       https://docs.oracle.com/en/java/javase/19/docs/api/java.base/java/util/UUID.html#structure()
  #
  #       I think it makes more sense for it to count upward like `version` rather than use the raw bit value.
  def structure
    return -1 unless self.rules.eql?(1)
    # Can't use getter for this since the getter return value will rely on this structure.
    clock_seq_high_and_reserved = ((self.inner_spirit >> 56) & 0xFF)
    # The structure is masked backwards, but with a variable number of bits,
    # so we can't just swap it and mask.
    case
    when (clock_seq_high_and_reserved >> 7).zero?       then 0
    when (clock_seq_high_and_reserved >> 6).eql?(0b10)  then 1
    when (clock_seq_high_and_reserved >> 5).eql?(0b110) then 2
    when (clock_seq_high_and_reserved >> 5).eql?(0b111) then 3
    end
  end

  # TODO: Convert this into `#replace` or just remove it, because assignment methods in Ruby can only return their argument.
  def structure=(otra)
    raise ::ArgumentError::new("invalid structure #{otra.to_s}") unless otra.respond_to?(:<) and otra.<(4)
    return self.with(
      inner_spirit: (
        (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_00FFFFFF_FFFFFFFF) |
        (
          (
            (case otra
              when 0    then 0b00000000
              when 1    then 0b10000000
              when 2    then 0b11000000
              when 3    then 0b11100000
              else      raise ::ArgumentError::new("invalid structure #{otra.to_s}")
            end) |
            (self.clock_seq_high_and_reserved & case otra
              when 0    then 0b01111111
              when 1    then 0b00111111
              when 2, 3 then 0b00011111
              else      raise ::ArgumentError::new("invalid structure #{otra.to_s}")
              end)
          ) << 56
        )
      ),
      structure: otra,
    )
  end

end
