# `::String`-printing components.
module ::GlobeGlitter::SAY_YEEEAHH

  # ITU-T Rec. X.667 sez —
  #
  # “Each field is treated as an integer and has its value printed as a
  # *zero-filled* hexadecimal digit string with the most significant digit first.”
  #    ^--- (emphasis mine)
  #
  # Convert a given `::Integer` to a hexadecimal `::String`, and prepend `0` characters
  # until the new `::String` is as long as needed.
  def left_pad(wanted_size, component) = component.to_s(16).yield_self {
    _1.size.>=(wanted_size) ? _1 : _1.prepend(?0 * wanted_size.-(_1.size))
  }
  private(:left_pad)

  # SAY YEEEAHH
  def to_s(base=16)
    case base
    when 16 then
      # ITU-T Rec. X.667 sez —
      #
      # “Each field is treated as an integer and has its value printed as a
      #  zero-filled hexadecimal digit string with the most significant digit first.
      #  The hexadecimal values "a" through "f" are output as lower case characters.”
      ::Array[
        self.left_pad(8,  self.time_low),
        self.left_pad(4,  self.time_mid),
        self.left_pad(4,  self.time_high_and_version),
        self.left_pad(4,  self.clock_seq),
        self.left_pad(12, self.node),
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
  def to_urn = "urn:uuid:".concat(self.to_s).-@

end
