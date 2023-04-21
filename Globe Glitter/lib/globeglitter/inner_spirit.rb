# Bitslicing components.
module ::GlobeGlitter::INNER_SPIRIT

  # NOTE: These method names are based on big-endian representation of our buffer, i.e. MSB <-> LSB.
  #
  # ITU-T Rec. X.667 sez —
  #  “This Recommendation | International Standard specifies a sequence of octets for a UUID
  #   using the terms first and last. The first octet is also called "octet 15" and the last octet "octet 0".
  #   The bits within a UUID are also numbered as "bit 127" to "bit 0", with bit 127 as the most-
  #   significant bit of octet 15 and bit 0 as the least significant bit of octet 0.”
  #
  # I am going to 1-index the boundaries in these helper methods because I think the resulting numbers
  # are easier to remember, but our structure is otherwise identical to what's described in the quote.
  def bits127–96 = self.inner_spirit.get_value(:U32, 0)
  def bits95–80  = self.inner_spirit.get_value(:U16, 4)
  def bits79–64  = self.inner_spirit.get_value(:U16, 6)
  def bits63–56  = self.inner_spirit.get_value(:U8, 8)
  def bits55–48  = self.inner_spirit.get_value(:U8, 9)
  def bits47–0   = (self.inner_spirit.get_value(:U16, 10) << 32) | self.inner_spirit.get_value(:U32, 12)

  def bits127–96=(otra); self.inner_spirit.set_value(:U32, 0, otra); end
  def bits95–80=(otra);  self.inner_spirit.set_value(:U16, 4, otra); end
  def bits79–64=(otra);  self.inner_spirit.set_value(:U16, 6, otra); end
  def bits63–56=(otra);  self.inner_spirit.set_value(:U8, 8, otra);  end
  def bits55–48=(otra);  self.inner_spirit.set_value(:U8, 9, otra);  end
  def bits47–0=(otra)
    self.inner_spirit.set_value(:U16, 10, otra >> 32)
    self.inner_spirit.set_value(:U32, 12, otra & 0xFFFFFFFF)
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
  def rules = (self.to_i >> 76) & 0xF
    # NOTE: Assignment methods in Ruby can only return their argument, so we name this `replace` instead.
  def replace_rules(otra)
    raise ::ArgumentError::new("invalid version #{otra.to_s}") unless otra.is_a?(::Integer) and otra.between?(1, 8)
    return self.with(rules: otra).tap {
      _1.inner_spirit.set_value(:U8, 7, ((otra << 0xF) | (self.inner_spirit.get_value(:U8, 7) & 0xF)))
    }
  end
  # This is just straight-up the same thing as "version" in the UUID specification,
  # but I don't want to call it that because it's a terrible ambiguous word
  # for anybody unfamiliar with the minutae of the specs.
  # We should still provide it as `#version` because why not??
  alias_method(:version, :rules)

  # ITU-T Rec. X.667 sez —
  #
  # “The variant field determines the layout of the UUID.
  #  That is, the interpretation of all other bits in the UUID depends on the setting
  #  of the bits in the variant field.  As such, it could more accurately be called a type field;
  #  we retain the original term for compatibility.
  #  The variant field consists of a variable number of the most significant bits of octet 8 of the UUID.
  #
  # “The following table lists the contents of the variant field, where
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
  # NOTE: Some libraries (like `java.util.UUID`) specify the variant value as if it were not backwards-masked:
  #       https://docs.oracle.com/en/java/javase/19/docs/api/java.base/java/util/UUID.html#variant()
  #
  #       I think it makes more sense for it to count upward like `version` rather than use the raw bit value.
  def structure
    # Can't use getter for this since the getter return value will rely on this structure.
    clock_seq_high_and_reserved = self.inner_spirit.get_value(:U8, 8)
    # The structure is masked backwards, but with a variable number of bits,
    # so we can't just swap it and mask.
    case
    when (clock_seq_high_and_reserved >> 7).zero?       then 0
    when (clock_seq_high_and_reserved >> 6).eql?(0b10)  then 1
    when (clock_seq_high_and_reserved >> 5).eql?(0b110) then 2
    when (clock_seq_high_and_reserved >> 5).eql?(0b111) then 3
    end
  end

    # NOTE: Assignment methods in Ruby can only return their argument, so we name this `replace` instead.
  def replace_structure(otra)
    raise ::ArgumentError::new("invalid structure #{otra.to_s}") unless otra.respond_to?(:<) and otra.<(4)
    return self.with(structure: otra).tap {
      _1.inner_spirit.set_value(:U8, 9,
        (
          (case otra
            when 0    then 0b00000000
            when 1    then 0b10000000
            when 2    then 0b11000000
            when 3    then 0b11100000
            else      raise ::ArgumentError::new("invalid structure #{otra.to_s}")
          end) |
          (_1.inner_spirit.get_value(:U8, 9) & case otra
            when 0    then 0b01111111
            when 1    then 0b00111111
            when 2, 3 then 0b00011111
            else      raise ::ArgumentError::new("invalid structure #{otra.to_s}")
            end)
        )
      )
    }
  end

  # Return `::Integer` representation of the contents of our embedded buffer.
  # ITU-T Rec. X.667 sez —
  # “A UUID can be represented as a single integer value. To obtain the single integer value of the UUID,
  #  the 16 octets of the binary representation shall be treated as an unsigned integer encoding with
  #  the most significant bit of the integer encoding as the most significant bit (bit 7) of the first
  #  of the sixteen octets (octet 15) and the least significant bit as the least significant bit (bit 0)
  #  of the last of the sixteen octets (octet 0).”
  # “UUIDs forming a component of an OID are represented in ASN.1 value notation
  # as the decimal representation of their integer value.”
  def to_i = (self.inner_spirit.get_value(:U64, 0) << 64) | self.inner_spirit.get_value(:U64, 8)

  # Compare to dotNET `Guid.ToByteArray` https://learn.microsoft.com/en-us/dotnet/api/system.guid.tobytearray
  # Match the naming of `::String#bytes` since we behave identically.
  def bytes = self.inner_spirit.values
  # Also keep the name `values` because why not lol
  def values = self.inner_spirit.values

end
