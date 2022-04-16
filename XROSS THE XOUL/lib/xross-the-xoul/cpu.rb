# Endian-swapping components live here.
#
# Little-endian systems:
# - VAX
# - x86 / AMD64
# Big-endian systems:
# - Motorola 68k
# - Internet https://en.wikipedia.org/wiki/Endianness#Networking
# - IBM mainframes
# Bi-endian systems:
# - AArch64
# - PowerPC / POWER
# - MIPS
# - Alpha
# - PA-RISC
# - SuperH
# - Itanium
# - RISC-V
#
# More reading:
# - https://betterexplained.com/articles/understanding-big-and-little-endian-byte-order/
# - http://fileformats.archiveteam.org/wiki/Endianness
#
# See Also:
# - `CoreFoundation`'s Byte Order Utilities:
#   https://developer.apple.com/documentation/corefoundation/byte-order_utilities
class XROSS; end
class XROSS::THE; end
class XROSS::THE::CPU

  # Determine the native endianness of the running system once at startup time.
  #
  # The computed constant value (`:<` or `:>`) matches the convention of `::Array#pack` directives,
  # per that method's RDoc:
  #   S> s> S!> s!> | Integer | same as the directives without ">" except
  #   L> l> L!> l!> |         | big endian
  #   I!> i!>       |         | (available since Ruby 1.9.3)
  #   Q> q> Q!> q!> |         | "S>" is same as "n"
  #   J> j> J!> j!> |         | "L>" is same as "N"
  #                 |         |
  #   S< s< S!< s!< | Integer | same as the directives without "<" except
  #   L< l< L!< l!< |         | little endian
  #   I!< i!<       |         | (available since Ruby 1.9.3)
  #   Q< q< Q!< q!< |         | "S<" is same as "v"
  #   J< j< J!< j!< |         | "L<" is same as "V"
  ORIGIN_OF_SYMMETRY = [1].yield_self { |bliss|
    # Pack the test Integer as a native-endianness 'I'nt and a 'N'etwork-endianess (BE) Int and compare.
    # NOTE: That the "'N'etwork endianness" directive here is different from
    #       the "'N'ative endianness" in the names of the `swapBtoN`/`swapLtoN` methods.
    bliss.pack(-?I) == bliss.pack(-?N) ? :> : :<
  }

  # e.g.
  #   irb> 0xBEEF => 48879
  #   irb> 0xEFBE => 61374
  #   irb> ::XROSS::THE::CPU::swap16(0xBEEF) => 61374
  #   irb> ::XROSS::THE::CPU::swap16(0xEFBE) => 48879
  def self.swap16(otra)
    otra = otra.to_i unless otra.is_a?(::Integer)
    ((otra << 8) & 0xFF00) | ((otra >> 8) & 0x00FF)
  end

  # e.g.
  #   irb> 0xEFBE3713 => 4022220563
  #   irb> 0x1337BEEF => 322420463
  #   irb> ::XROSS::THE::CPU::swap32(0xEFBE3713) => 322420463
  #   irb> ::XROSS::THE::CPU::swap32(0x1337BEEF) => 4022220563
  def self.swap32(otra)
    otra = otra.to_i unless otra.is_a?(::Integer)
    (((otra & 0x000000FF) << 24) |
     ((otra & 0x0000FF00) <<  8) |
     ((otra & 0x00FF0000) >>  8) |
     ((otra & 0xFF000000) >> 24))
  end

  # e.g. '\89PNG':
  #   irb> 0x89504E470D0A1A0A => 9894494448401390090
  #   irb> 0xA1A0A0D474E5089 => 727905341920923785
  #   irb> ::XROSS::THE::CPU::swap64(0x89504E470D0A1A0A) => 727905341920923785
  #   irb> ::XROSS::THE::CPU::swap64(0xA1A0A0D474E5089) => 9894494448401390090
  def self.swap64(otra)
    otra = otra.to_i unless otra.is_a?(::Integer)
    (((otra << 56) & 0xFF00000000000000) |
     ((otra << 40) & 0x00FF000000000000) |
     ((otra << 24) & 0x0000FF0000000000) |
     ((otra <<  8) & 0x000000FF00000000) |
     ((otra >>  8) & 0x00000000FF000000) |
     ((otra >> 24) & 0x0000000000FF0000) |
     ((otra >> 40) & 0x000000000000FF00) |
     ((otra >> 56) & 0x00000000000000FF))
  end

  # Automatically do The Right Thing™ based on the `#bit_length`, expressed as a `::Range`
  # because the `#bit_length` tells us the position of the most significant non-sign bit, e.g.:
  #   irb> 0b11100111.bit_length => 8
  #   irb> 0b00000111.bit_length => 3
  def self.swap(otra)
    otra = otra.to_i unless otra.is_a?(::Integer)
    case otra.bit_length
    when 0        then otra
    when (01..16) then self.swap16(otra)
    when (17..32) then self.swap32(otra)
    when (33..64) then self.swap64(otra)
    else raise ::ArgumentError::new("Unable to byte-swap #{otra} with unsupported `#bit_length` #{otra.bit_length}")
    end
  end

  # Byte-swap a number unless it's already in the CPU's native endianness.
  #
  # NOTE that the 'N' here stands for "'N'ative Endianness" and is different from
  #      the 'N' directive to `::Array#pack` which represents a 'N'etwork (Big) endian 32-bit int.
  #      We're following the same method-naming convention as Carbon's `Endian.h`.
  def self.swapBtoN(otra) = self::ORIGIN_OF_SYMMETRY.eql?(:>) ? otra : self.swap(otra)
  def self.swapLtoN(otra) = self::ORIGIN_OF_SYMMETRY.eql?(:<) ? otra : self.swap(otra)

end
