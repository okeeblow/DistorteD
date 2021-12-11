require('bundler/setup')
require('test/unit') unless defined?(::Test::Unit)
require_relative('../lib/xross-the-xoul/cpu') unless defined?(::XROSS::THE::CPU)

class TestXrossCPU < ::Test::Unit::TestCase

  # Test cases:

  SIXTEEN_BIT_VALUES = [
    0b1111111100000000,
    0x1234,
    0xFFD8,  # JFIF SOI (start-of-image)
  ]

  THIRTY_TWO_BIT_VALUES = [
    0b11111111000000001111111100000000,
    0x12345678,

    # libpcap magic: https://wiki.wireshark.org/Development/LibpcapFileFormat#Global_Header
    0xa1b2b3d4,  # Seconds-resolution capture.
    0xa1b23c4d,  # Nanoseconds-resolution capture.
  ]

  SIXTY_FOUR_BIT_VALUES = [
    0x89504E470D0A1A0A,  # '\x89PNG'
  ]

  # Method-body generator.
  SWAP_DOT_AVI = ->(corpus, xross, directives) {
    ::Proc::new {
      corpus.each {

        # Compare our swap code to `::Array#pack`.
        assert_equal(
          ::XROSS::THE::CPU::send(xross, _1),
          ::Kernel::Array(_1).pack(directives.first).unpack1(directives.last),
        )

        # Two invocations of our swap code should cancel out.
        assert_equal(
          _1,
          ::XROSS::THE::CPU::send(xross, ::XROSS::THE::CPU::send(xross, _1)),
        )

        # The generic `::byteswap` method should detect and use the appropriate-length
        # swap method based on the `#bit_length` of the test value.
        assert_equal(
          ::XROSS::THE::CPU::send(xross, _1),
          ::XROSS::THE::CPU::byteswap(_1),
        )

      }  # corpus.each
    }  # `::Proc::new`
  }

  # Per `::Array#pack` RDoc:
  # 
  # Q_ Q!         | Integer | unsigned long long, native endian (ArgumentError
  #               |         | if the platform has no long long type.)
  #               |         | (Q_ and Q! is available since Ruby 2.1.)
  PLATFORM_HAS_LONG_LONG = begin
    ::Kernel::Array(SIXTY_FOUR_BIT_VALUES.first).pack(-'Q!')
    true
  rescue ::ArgumentError
    false
  end

  def test_detect_system_endianness
    assert_include([:>, :<], ::XROSS::THE::CPU::ORIGIN_OF_SYMMETRY)
  end

  define_method(:test_byte_swap_16, SWAP_DOT_AVI.call(SIXTEEN_BIT_VALUES,    :byteswap16, [-?n, -?v]))
  define_method(:test_byte_swap_32, SWAP_DOT_AVI.call(THIRTY_TWO_BIT_VALUES, :byteswap32, [-?N, -?V]))
  define_method(:test_byte_swap_64, SWAP_DOT_AVI.call(SIXTY_FOUR_BIT_VALUES, :byteswap64, ['Q>', 'Q<'])) if PLATFORM_HAS_LONG_LONG

end
