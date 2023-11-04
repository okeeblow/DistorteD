# Bitslicing components.
module ::GlobeGlitter::INNER_SPIRIT

  # NOTE: All method names are based on big-endian representation of our buffer, i.e. MSB <-> LSB.
  #
  # ITU-T Rec. X.667 sez —
  #  “This Recommendation | International Standard specifies a sequence of octets for a UUID
  #   using the terms first and last. The first octet is also called "octet 15" and the last octet "octet 0".
  #   The bits within a UUID are also numbered as "bit 127" to "bit 0", with bit 127 as the most-
  #   significant bit of octet 15 and bit 0 as the least significant bit of octet 0.”

  # These are used for most time-based and random UUIDs.
  def bits127–96 = ((self.inner_spirit >> 96) & 0xFFFFFFFF)
  def bits95–80  = ((self.inner_spirit >> 80) & 0xFFFF)
  def bits79–64  = ((self.inner_spirit >> 64) & 0xFFFF)
  def bits63–56  = ((self.inner_spirit >> 56) & 0xFF)
  def bits55–48  = ((self.inner_spirit >> 48) & 0xFF)
  def bits47–0   =  (self.inner_spirit        & 0xFFFFFFFFFFFF)

  # This one is used for MSSQL-style comparison (based on groups delimited
  # by the `-` of the hex `::String` representation):
  # `https://web.archive.org/web/20190122185434/https://blogs.msdn.microsoft.com/
  #  sqlprogrammability/2006/11/06/how-are-guids-compared-in-sql-server-2005/`
  def bits63–48  = ((self.inner_spirit >> 48) & 0xFFFF)

  # This one is used for `java.util.UUID`-style comparison.
  def bits127–64 = ((self.inner_spirit >> 64) & 0xFFFFFFFF_FFFFFFFF)

  # This one is used for building Microsoft GUID-style `data4`s as well as for
  # `java.util.UUID`-style comparison.
  def bits63–0   =  (self.inner_spirit        & 0xFFFFFFFF_FFFFFFFF)

  # These are used for `Platform::Guid`-style comparison.
  # https://learn.microsoft.com/en-us/cpp/cppcx/platform-guid-value-class sez —
  # “The ordering is lexicographic after treating each `Platform::Guid` as if it's an array
  #  of four 32-bit unsigned values.”
  def bits95–64  = ((self.inner_spirit >> 64) & 0xFFFFFFFF)
  def bits63–32  = ((self.inner_spirit >> 32) & 0xFFFFFFFF)
  def bits31–0   =  (self.inner_spirit        & 0xFFFFFFFF)

  def with_bits127–96(otra) = self.with(inner_spirit: self.replace_bits127–96(otra))
  def with_bits95–80(otra)  = self.with(inner_spirit: self.replace_bits95–80(otra))
  def with_bits79–64(otra)  = self.with(inner_spirit: self.replace_bits79–64(otra))
  def with_bits63–56(otra)  = self.with(inner_spirit: self.replace_bits63–56(otra))
  def with_bits55–48(otra)  = self.with(inner_spirit: self.replace_bits55–48(otra))
  def with_bits47–0(otra)   = self.with(inner_spirit: self.replace_bits47–0(otra))
  def with_bits63–48(otra)  = self.with(inner_spirit: self.replace_bits63–48(otra))
  def with_bits63–0(otra)   = self.with(inner_spirit: self.replace_bits63–0(otra))

  def replace_bits127–96(otra) = (self.inner_spirit & 0x00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF) | (otra << 96)
  def replace_bits95–80(otra)  = (self.inner_spirit & 0xFFFFFFFF_0000FFFF_FFFFFFFF_FFFFFFFF) | (otra << 80)
  def replace_bits79–64(otra)  = (self.inner_spirit & 0xFFFFFFFF_FFFF0000_FFFFFFFF_FFFFFFFF) | (otra << 64)
  def replace_bits63–56(otra)  = (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_00FFFFFF_FFFFFFFF) | (otra << 56)
  def replace_bits55–48(otra)  = (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_FF00FFFF_FFFFFFFF) | (otra << 48)
  def replace_bits47–0(otra)   = (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_FFFF0000_00000000) |  otra
  def replace_bits63–48(otra)  = (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_0000FFFF_FFFFFFFF) | (otra << 48)
  def replace_bits63–0(otra)   = (self.inner_spirit & 0xFFFFFFFF_FFFFFFFF_00000000_00000000) |  otra


  # ITU-T Rec. X.667 sez —
  #
  # “The version number is in the most significant 4 bits of the time
  #  stamp (bits 4 through 7 of the time_hi_and_version field).”
  #
  # “The following table lists the currently-defined versions for this UUID variant.”
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
  def version = (self.inner_spirit >> 76) & 0xF

  # NOTE: Assignment methods in Ruby can only return their argument,
  #       so we name this `:replace_behavior` instead of `:behavior=`
  #       because we want to return `self`.
  def with_behavior(otra)
    raise ::ArgumentError::new("invalid version #{otra.to_s}") unless otra.is_a?(::Integer) and otra.between?(1, 8)
    return self.with(
      behavior: otra,
      inner_spirit: self.replace_version(otra),
    )
  end

  def replace_version(otra)
    raise ::ArgumentError::new("invalid version #{otra.to_s}") unless otra.is_a?(::Integer) and otra.between?(1, 8)
    (self.inner_spirit & 0xFFFFFFFF_FFFFFF0F_FFFFFFFF_FFFFFFFF) | (otra << 76)
  end

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
  #    1     0     x    The variant specified in this document.
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
  def variant
    # TODO: Figure out how this should interact with our instance `layout` member
    #       since only certain variants should be embedded here.
    # Can't use getter for this since the getter return value will rely on this layout.
    clock_seq_high_and_reserved = (self.inner_spirit >> 64) & 0xF
    # The variant is masked backwards, but with a variable number of bits,
    # so we can't just swap it and mask.
    case
    when (clock_seq_high_and_reserved >> 7).zero?       then 0
    when (clock_seq_high_and_reserved >> 6).eql?(0b10)  then 1
    when (clock_seq_high_and_reserved >> 5).eql?(0b110) then 2
    when (clock_seq_high_and_reserved >> 5).eql?(0b111) then 3
    end
  end

  # NOTE: Assignment methods in Ruby can only return their argument,
  #       so we name this `:replace_layout` instead of `:layout=`
  #       because we want to return `self`.
  def with_layout(otra)
    raise ::ArgumentError::new("invalid layout #{otra.to_s}") unless otra.respond_to?(:<) and otra.<(4)
    return self.with(
      layout: otra,
      inner_spirit: self.replace_variant(otra),
    )
  end

  def replace_variant(otra)
    raise ::ArgumentError::new("invalid layout #{otra.to_s}") unless otra.respond_to?(:<) and otra.<(4)
    (self.inner_spirit & case otra
      when 0    then 0b01111111
      when 1    then 0b00111111
      when 2, 3 then 0b00011111
    end) | case otra
      when 0    then 0b00000000
      when 1    then 0b10000000
      when 2    then 0b11000000
      when 3    then 0b11100000
    end
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
  def to_i = self.inner_spirit

  # Compare to dotNET `Guid.ToByteArray` https://learn.microsoft.com/en-us/dotnet/api/system.guid.tobytearray
  # Match the naming of `::String#bytes` since we behave identically.
  # Explicitly loop 16 times to handle most-significant zeros that `until quotient.zero?`-style loop won't.
  # TODO: Revise `#times` count when I get around to implementing 64-bit UIDs and 256-bit UUIDs.
  def bytes = (0xF.succ).times.with_object(
    # Prime our scratch area with a copy of the main value buffer as the first dividend. I would prefer to
    # avoid allocation of the scratch `::Array` since it will contain only a single value at every iterator,
    # but we have to use a mutable object with `with_object` — trying it with an immediate (i.e. `::Integer`)
    # results in the same value every loop despite any in-loop reassignment.
    ::Array::new.push(self.inner_spirit)
  ).with_object(::Array::new) { |(_position, scratch), bytes|
    quotient, modulus = scratch.pop.divmod(0xFF.succ)
    scratch.push(quotient)
    bytes.unshift(modulus)
  }

end
