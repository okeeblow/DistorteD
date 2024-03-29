require('xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)


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
    when 2  then self.inner_spirit.to_s(2).rjust(
      case self.layout
        when self.class::LAYOUT_AEGIS     then 64
        #when self.class::LAYOUT_COHERENCE then 256  TODO: Coherence-style 256-bit UUIDs
        else                                   128
      end,
      ?0)
    when 16 then
      if self.layout.eql?(self.class::LAYOUT_NCS) then
        ::Array[
          # `<time>.<address-family>.<h.o.s.t.i.d>`
          self.bits127–80.to_s(16).rjust(12, ?0),
          self.bits63–56.to_s(16).rjust(2, ?0),
          *(7.times.with_object(self.bits55–0).with_object(::Array::new) { |(which, fiftysix), out|
            out.unshift((fiftysix >> (which * 8) & 0xFF))
          }.map! { _1.to_s(16).rjust(2, ?0) })
        ].join(?.).encode!(::Encoding::US_ASCII).-@
      else
        # ITU-T Rec. X.667 sez —
        #
        # “Each field is treated as an integer and has its value printed as a
        #  zero-filled hexadecimal digit string with the most significant digit first.
        #  The hexadecimal values "a" through "f" are output as lower case characters.”
        ::Array[
          # GUIDs (a.k.a Microsoft layout) are stored little-endian and must be reversed to be printed.
          # Note that the lsb 64 bits represent a GUID's `data4`. i.e. an array of octets which are the same
          # in either endianness. This is why we only swap `data1`, `data2`, and `data3`.
          (
            self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap32(self.bits127–96) : self.bits127–96
          ).to_s(16).rjust(8, ?0),
          (
            self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(self.bits95–80)  : self.bits95–80
          ).to_s(16).rjust(4, ?0),
          (
            self.layout.eql?(self.class::LAYOUT_MICROSOFT) ? ::XROSS::THE::CPU::swap16(self.bits79–64)  : self.bits79–64
          ).to_s(16).rjust(4, ?0),
          self.bits63–48.to_s(16).rjust(4, ?0),
          self.bits47–0.to_s(16).rjust(12, ?0),
        ].join(?-).encode!(::Encoding::US_ASCII).tap {
          (_1.upcase! && _1.prepend(?{) && _1.concat(?})) if self.layout.eql?(self.class::LAYOUT_MICROSOFT)
        }.-@
      end
    else
      # Compare to `::Integer#to_s` behavior:
      #   irb> 333.to_s(666)
      #   (irb):in `to_s': invalid radix 666 (ArgumentError)
      raise ::ArgumentError::new("invalid radix #{base.to_s}")
    end
  end

  # In Microsoft-land, GUIDs were ALL-CAPS hex packaged between curly braces
  def to_guid = ::String::new("{#{self.to_s(16).upcase}}", encoding: ::Encoding::US_ASCII)

  def inspect = ::String::new("#<#{self.class.name} #{self.to_s}>", encoding: ::Encoding::US_ASCII)

  # ITU-T Rec. X.667 sez —
  # “An alternative URN format [alternative to `"urn:uuid:<hex-string>"`] is available,
  #  but is not recommended for URNs generated using UUIDs.
  #  This alternative format uses the single integer value of the UUID, and represents the UUID
  #  `f81d4fae-7dec-11d0-a765-00a0c91e6bf6` as `urn:oid:2.25.329800735698586629295641978511506172918`.”
  #
  # Explicitly call `#to_i#to_s` to avoid `RangeError: bignum out of char range`.
  def to_oid = ::String::new("urn:oid:2.25.".concat(self.to_i.to_s), encoding: ::Encoding::US_ASCII).-@

  # ITU-T Rec. X.667 sez —
  # “A UUID can be used as the primary integer value of a Joint UUID arc using the single integer value of the UUID.
  #  The hexadecimal representation of the UUID can also be used as a non-integer Unicode label for the arc.
  #  EXAMPLE — The following is an example of the use of a UUID to form an IRI/URI value: 
  #            "oid:/UUID/f81d4fae-7dec-11d0-a765-00a0c91e6bf6"”
  def to_oid_s = ::String::new("oid:/UUID/".concat(self.to_s(base=16)), encoding: ::Encoding::US_ASCII).-@

  # ITU-T Rec. X.667 sez —
  # “The string representation of a UUID is fully compatible with the URN syntax.
  #  When converting from a bit-oriented, in-memory representation of a UUID into a URN,
  #  care must be taken to strictly adhere to the byte order issues
  #  mentioned in the string representation section.”
  # “The following is an example of the string representation of a UUID as a URN:
  #   urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6”
  def to_urn = ::String::new("urn:uuid:".concat(self.to_s(base=16)), encoding: ::Encoding::US_ASCII).-@

  # TODO: `#to_clsid` https://www.w3.org/Addressing/clsid-scheme

end
