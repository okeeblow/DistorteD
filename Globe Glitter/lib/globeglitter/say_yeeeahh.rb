# `::String`-printing components.
module ::GlobeGlitter::SAY_YEEEAHH

  # SAY YEEEAHH
  # NOTE: Built-in Ruby classes emit `US-ASCII` as their `#to_s`, thus so shall we.
  #       Some relevant discussions:
  #       - In https://bugs.ruby-lang.org/issues/7752 `naruse` sez —
  #         “On current policy, strings which always include only US-ASCII characters are US-ASCII.
  #          If there is a practical issue, I may change the policy in the future.
  #          Note that US-ASCII string is faster than UTF-8 on getting length or index access.”
  #       - `::Time`:       https://bugs.ruby-lang.org/issues/6820
  #       - `::Integer`:    https://bugs.ruby-lang.org/issues/15876
  #       - `::BigDecimal`: https://bugs.ruby-lang.org/issues/17011
  def to_s(base=16)
    case base
    when 2  then self.to_i.to_s(2).rjust(128, ?0)
    when 16 then
      # ITU-T Rec. X.667 sez —
      #
      # “Each field is treated as an integer and has its value printed as a
      #  zero-filled hexadecimal digit string with the most significant digit first.
      #  The hexadecimal values "a" through "f" are output as lower case characters.”
      ::Array[
        # TODO: Handle swapping for String representation of MS-style GUIDs
        self.time_low.to_s(16).rjust(8, ?0),
        self.time_mid.to_s(16).rjust(4, ?0),
        self.time_high_and_version.to_s(16).rjust(4, ?0),
        self.clock_seq.to_s(16).rjust(4, ?0),
        self.node.to_s(16).rjust(12, ?0),
      ].join(?-).-@
    else
      # Compare to `::Integer#to_s` behavior:
      #   irb> 333.to_s(666)
      #   (irb):in `to_s': invalid radix 666 (ArgumentError)
      raise ::ArgumentError::new("invalid radix #{base.to_s}")
    end
  end

  def inspect = "#<#{self.class.name} #{self.to_s}>"

  # ITU-T Rec. X.667 sez —
  #
  # “The string representation of a UUID is fully compatible with the URN syntax.
  #  When converting from a bit-oriented, in-memory representation of a UUID into a URN,
  #  care must be taken to strictly adhere to the byte order issues
  #  mentioned in the string representation section.”
  # “The following is an example of the string representation of a UUID as a URN:
  #   urn:inner_spirit:f81d4fae-7dec-11d0-a765-00a0c91e6bf6”
  def to_urn = "urn:uuid:".concat(self.to_s(base=16)).-@

  # TODO: `#to_clsid` https://www.w3.org/Addressing/clsid-scheme

end
