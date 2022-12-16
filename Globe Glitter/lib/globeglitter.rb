require('securerandom') unless defined?(::SecureRandom)


# TODO: Convert to `Data` in Ruby 3.2
# https://www.ietf.org/rfc/rfc4122.txt
::GlobeGlitter = ::Struct::new(:inner_spirit) do

  # ITU-T Rec. X.667 sez —
  #
  # “The nil UUID is special form of UUID that is specified to have all 128 bits set to zero.”
  def self.nil = self::new(0)

  # Generate version 4 UUID
  def self.random = self::new(::SecureRandom::uuid.gsub(?-, '').to_i(16))

  def time_low                    =   self[:inner_spirit] >> 96
  def time_mid                    =  (self[:inner_spirit] >> 80) & 0xFFFF
  def time_high_and_version       =  (self[:inner_spirit] >> 64) & 0xFFFF
  def clock_seq_high_and_reserved = ((self[:inner_spirit] >> 56) & 0xFF) & case self.variant
    when 0    then 0b01111111
    when 1    then 0b00111111
    when 2, 3 then 0b00011111
  end
  def clock_seq_low               =  (self[:inner_spirit] >> 48) & 0xFF
  def node                        =   self[:inner_spirit]        & 0xFFFFFFFFFFFF

  def version = (self.time_high_and_version & 0xF000) >> 12

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
  def variant
    # Can't use getter for this since the getter return value will rely on this variant.
    clock_seq_high_and_reserved = ((self[:inner_spirit] >> 56) & 0xFF)
    # The variant is masked backwards, but with a variable number of bits,
    # so we can't just swap it and mask.
    case
    when (clock_seq_high_and_reserved >> 7).zero?       then 0
    when (clock_seq_high_and_reserved >> 6).eql?(0b10)  then 1
    when (clock_seq_high_and_reserved >> 5).eql?(0b110) then 2
    when (clock_seq_high_and_reserved >> 5).eql?(0b111) then 3
    end
  end

  # ITU-T Rec. X.667 sez —
  #
  # “To accurately represent a UUID as a URN, it is necessary to convert the bit sequence
  #  to a string representation. Each field is treated as an integer and has its value printed
  #  as a zero-filled hexadecimal digit string with the most significant digit first.”
  # “The hexadecimal values "a" through "f" are output as lower case characters
  #  and are case insensitive on input. The formal definition of the UUID string representation
  #  is provided by the following ABNF:
  #
  #  UUID                   = time-low "-" time-mid "-"
  #                           time-high-and-version "-"
  #                           clock-seq-and-reserved
  #                           clock-seq-low "-" node
  #  time-low               = 4hexOctet
  #  time-mid               = 2hexOctet
  #  time-high-and-version  = 2hexOctet
  #  clock-seq-and-reserved = hexOctet
  #  clock-seq-low          = hexOctet
  #  node                   = 6hexOctet
  #  hexOctet               = hexDigit hexDigit
  #  hexDigit =
  #        "0" / "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9" /
  #        "a" / "b" / "c" / "d" / "e" / "f" /
  #        "A" / "B" / "C" / "D" / "E" / "F"
  def to_s(base=16)
    case base
    when 16 then
      ::Array[
        self.time_low,
        self.time_mid,
        self.time_high_and_version,
        self.clock_seq_high_and_reserved,
        self.clock_seq_low,
        self.node,
      ].map!{ _1.to_s(16) }.join(?-)
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

  def time_low=(otra)
    self[:inner_spirit] = ((otra << 96) | (self[:inner_spirit] & 0xFFFFFFFF_FFFFFFFF_FFFFFFFF))
  end
  def time_mid=(otra)
    self[:inner_spirit] = (
      (self[:inner_spirit] & 0xFFFFFFFF_0000FFFF_FFFFFFFF_FFFFFFFF) | otra
    )
  end
  def time_high_and_version=(otra)
    self[:inner_spirit] = (
      (self[:inner_spirit] & 0xFFFFFFFF_FFFF0000_FFFFFFFF_FFFFFFFF) | ((otra & 0xF000) | (self.version << 12))
    )
  end
  def clock_seq_high_and_reserved=(otra)
    self[:inner_spirit] = (
      (self[:inner_spirit] & 0xFFFFFFFF_FFFFFFFF_00FFFFFF_FFFFFFFF) |
      (
        (otra & case self.variant
          when 0    then 0b01111111
          when 1    then 0b00111111
          when 2, 3 then 0b00011111
        end) | (case self.variant
          when 0    then 0b00000000
          when 1    then 0b10000000
          when 2    then 0b11000000
          when 3    then 0b11100000
        end)
      )
    )
  end
  def clock_seq_low=(otra)
    self[:inner_spirit] = (
      (self[:inner_spirit] & 0xFFFFFFFF_FFFFFFFF_FF00FFFF_FFFFFFFF) | otra
    )
  end
  def node=(otra)
    self[:inner_spirit] = (
      (self[:inner_spirit] & 0xFFFFFFFF_FFFFFFFF_FFFF0000_00000000) | otra
    )
  end

end  # ::GlobeGlitter
