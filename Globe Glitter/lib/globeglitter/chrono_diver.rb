require('securerandom') unless defined?(::SecureRandom)
require('socket') unless defined?(::Socket)
require('xross-the-xoul/network') unless defined?(::XROSS::THE::NETWORK)
require_relative('chrono_seeker') unless defined?(::GlobeGlitter::CHRONO_SEEKER)


# Components for time-based identifiers
# (Apollo AEGIS UIDs, Apollo NCS UUIDs, Gregorian UUIDs, Unixtime UUIDs, etc).
module ::GlobeGlitter::CHRONO_DIVER

  # Apollo Computer Incorporated was founded in 1980. UIDs were envisioned as identifiers for messages
  # in Apollo's distributed-computing architecture, so none of those identifiers would be older than 1980.
  EPOCH_APOLLO             = ::Time::new(1980, 1, 1, 0, 0, 0, in: ?Z)
  # https://en.wikipedia.org/wiki/Gregorian_calendar
  EPOCH_GREGORIAN          = ::Time::new(1582, 10, 15, 0, 0, 0, in: ?Z)

  # Ruby `::Time` gives us seconds.
  NANOSECONDS_IN_SECOND    = 1_000_000_000
  MICROSECONDS_IN_SECOND   = 1_000_000
  MILLISECONDS_IN_SECOND   = 1_000

  # Minimum possible interval between sequential time-based identifiers.
  GREGORIAN_UUID_TICK_RATE = 100
  NCS_UUID_TICK_RATE       = 4
  AEGIS_UID_TICK_RATE      = 16   # “34.8 Years worth of Uniqueness (2014 !!)” lol

end


module ::GlobeGlitter::CHRONO_DIVER::PENDULUMS

  # http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=379
  # “The first issue to deal with was choosing the size of the UID. We had a 48 bit 4 microsecond basic system clock,
  #  but that, plus a 20 bit node ID, and a few bits for future expansion, seemed to imply a UID that we felt
  #  would be a bit long. We settled on a 36 bit creation time, which meant a 16 millisecond resolution.
  #  We justified it by noting that, since most objects reside on disk, they can't be created faster than disk speeds;
  #  36 bits allowed. a resolution several times higher. To allow for possibly bursty UID generation,
  #  the system remembers unused UIDs from the previous minute or so, and uses them before generating new ones.”
  def current_raw_aegis_time = (
    ((::Time::now.utc - ::GlobeGlitter::CHRONO_DIVER::EPOCH_APOLLO) *
      ::GlobeGlitter::CHRONO_DIVER::MILLISECONDS_IN_SECOND)         /
      ::GlobeGlitter::CHRONO_DIVER::AEGIS_UID_TICK_RATE
  ).to_i

  # This rolls over in 2014:
  #   irb> GlobeGlitter::new(0xFFFFFFFFF, 0, 0xC0017, layout: -1).to_s(2)
  #   => "1111111111111111111111111111111111110000000011000000000000010111"
  #   irb> GlobeGlitter::new(0xFFFFFFFFF, 0, 0xC0017, layout: -1).to_time
  #   => 2014-11-03 19:53:36 UTC
  def current_aegis_time = (self.current_raw_aegis_time % 0xFFFFFFFFF)  # 36 bits

  # TODO: Take `::Time` argument
  def from_aegis_time = self::new(
    current_aegis_time,
    0,  # This reserved field is always zero.
    current_node & 0b11111_11111_11111_11111,  # 20 bits of interface address.
    layout: ::GlobeGlitter::LAYOUT_AEGIS,
    behavior: ::GlobeGlitter::BEHAVIOR_TIME_APOLLO,
  )

  # NCS UUIDs (i.e. "variant 0" UUIDs) dedicate one octet to represent
  # the network Address Family of the host generating the UUID.
  #
  # RE: `AF` vs `PF`, https://beej.us/guide/bgnet/html/ sez —
  # “This `PF_INET` thing is a close relative of the `AF_INET` that you can use when initializing
  #  the `sin_family` field in your struct `sockaddr_in`. In fact, they’re so closely related that
  #  they actually have the same value, and many programmers will call `socket()` and pass `AF_INET`
  #  as the first argument instead of `PF_INET`.”
  # “Now, get some milk and cookies, because it’s time for a story. Once upon a time, a long time ago,
  #  it was thought that maybe an address family (what the “AF” in “AF_INET” stands for) might
  #  support several protocols that were referred to by their protocol family (what the “PF”
  #  in “PF_INET” stands for). That didn’t happen. And they all lived happily ever after, The End.
  #  So the most correct thing to do is to use `AF_INET` in your struct `sockaddr_in`
  #  and `PF_INET` in your call to `socket()`.”
  #
  # The NCS spec says "addr fam", so I am specifically choosing `::AddrInfo#afamily` over `#pfamily`.
  #
  # NOTES:
  # - IANA maintains "The List" of standardized AFs https://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml
  # - Apollo's Network Computing Kernel defines `socket_$valid_family` based on the presence of a "handler" for each AF.
  #   - NCK is very old and only knows about AFs 0–13.
  #   - Of those, only AF_INET (2) and AF_DDS (13) have defined handlers, and even those are optional behind `#ifdef`s.
  #     - This is reflected in the release notes for Domain/OS 10.1:
  #       http://www.bitsavers.org/pdf/apollo/release_notes/005809-A03_10.1_Release_Notes_Dec88.pdf#page=61
  #       “The application interface can simultaneously support both the Internet IP and the Domain DDS network protocols.
  #        The replication interface, which formerly supported only DDS protocols, can now use either IP or DDS (but not both).”
  #     - https://web.archive.org/web/20060712084433/http://shekel.jct.ac.il/~roman/tcp-ip-lab/ibm-tutorial/3376c411.html
  #       “The NCS RPC can use the Domain network communications protocols (DDS) and the DARPA Internet Protocols (UDP/IP).
  #        The selection is made by the destination address given so that a program can access a Domain and non-Domain entity.”
  #   - What NCK knows as AF 13 (Domain Datagram Service) seems to be different from the IANA-registered AF 13 (DECnet4).
  #     - DCE 1.1 RPC spec mentions DDS and DECnet4 side-by-side, calling DECnet `dnet`.
  #     - Based on the name I assume AF_DDS is an Apollo/DOMAIN thing:
  #       https://bitsavers.org/pdf/apollo/014962-A00_Domain_OS_Design_Principles_Jan89.pdf#page=150
  #       “We have already implemented a manager for "Domain domain sockets." Currently, this domain supports
  #        only datagram-oriented sockets (SOCK_DGRAM) because our short-term goal was merely to allow access to specific,
  #        low-level Domain networking primitives using the generic, high-level socket calls.”
  #       - Not sure if "Domain domain sockets" there is a typo or if they meant "Domain datagram sockets"
  #         but either way the initialism fits AF_DDS lol
  #     - In AEGIS, DDS was “The ONLY Apollo packet delivery mechanism —
  #         Available to user space through the (unreleased/undocumented) "MSG" interface.”
  #         http://bitsavers.org/pdf/apollo/AEGIS_Overview_1985.pdf#page=150
  # - NCS UUID layout provides 8 bits to encode the Address Family.
  #   - Since NCK only knows up to AF_DDS (13), only four (4) of those bits would ever be used in practice.
  #   - The leftover 0-bits are how the modern RFC/ITU UUID spec differentiates UUID variants,
  #     declaring that a 0 signifies "Reserved, NCS backwards comparibility".
  #   - However NCS never actually guarantees that bit would be zero!
  #     It just was always that way in practice due to the low number of Address Families.
  #     In fact even as I write this in 2023, AFs 32–16383 are undefined.
  #
  # Conclusion: For forward-compatibility, we will ensure the 0-bit `variant` is set for NCS UUIDs
  #             even if some yet-undefined Address Family could technically make that not so.
  #             irb> 0b01111111 => 127
  def primary_address_family = ::Socket.ip_address_list.map!(&:afamily).keep_if { _1 <= 127 }.first

  # NCK `uuid.c` sez —
  #  “The first 48 bits are the number of 4 usec units of time that have passed since 1/1/80 0000 GMT.
  #   The next 16 bits are reserved for future use. The next 8 bits are an address family.
  #
  #       |<------------------- 32 bits --------------------->|
  #
  #       +---------------------------------------------------+
  #       |           high 32 bits of bit time                |
  #       +------------------------+--------------------------+
  #       |   low 16 bits of time  |     16 bits reserved     |
  #       +------------+-----------+--------------------------+
  #       | addr fam   |      1st 24 bits of host ID          |
  #       +------------+-----------+--------------------------+
  #       |            32 more bits of host ID                |
  #       +---------------------------------------------------+
  def current_raw_ncs_time = (
    ((::Time::now.utc - ::GlobeGlitter::CHRONO_DIVER::EPOCH_APOLLO) *
      ::GlobeGlitter::CHRONO_DIVER::MICROSECONDS_IN_SECOND)         /
      ::GlobeGlitter::CHRONO_DIVER::NCS_UUID_TICK_RATE
  ).to_i

  # This rolls over in 2015:
  #   irb> GlobeGlitter::new(0xFFFFFFFFFFFF, 0, 0x1b, 0xC0017232, layout: 0).to_s(2)
  #   => "11111111111111111111111111111111111111111111111100000000000000000001101100000000000000000000000011000000000000010111001000110010"
  #   irb> GlobeGlitter::new(0xFFFFFFFFFFFF, 0, 0x1b, 0xC00172e2, layout: 0).to_time
  #   => 2015-09-05 05:58:24 UTC
  def current_ncs_time = (self.current_raw_ncs_time % 0xFFFFFFFFFFFF)  # 48 bits

  # TODO: Take `::Time` argument
  def from_ncs_time = self::new(
    current_ncs_time,
    0,
    primary_address_family,
    current_node,
    layout: ::GlobeGlitter::LAYOUT_NCS,
    behavior: ::GlobeGlitter::BEHAVIOR_TIME_APOLLO,
  )

  # ITU-T Rec. X.667 sez —
  #
  #  “The timestamp is a 60-bit value.  For UUID version 1, this is
  #   represented by Coordinated Universal Time (UTC) as a count of 100-
  #   nanosecond intervals since 00:00:00.00, 15 October 1582 (the date of
  #   Gregorian reform to the Christian calendar).“
  #  “For systems that do not have UTC available, but do have the local
  #   time, they may use that instead of UTC, as long as they do so
  #   consistently throughout the system.  However, this is not recommended
  #   since generating the UTC from local time only needs a time zone offset.”
  #  “Since a UUID is a fixed size and contains a time field,
  #   it is possible for values to rollover (around A.D. 3400,
  #   depending on the specific algorithm used).”
  #  “NT keeps time in FILETIME format which is 100ns ticks since Jan 1, 1601.
  #   UUIDs use time in 100ns ticks since Oct 15, 1582.
  #   The difference is 17 Days in Oct + 30 (Nov) + 31 (Dec) + 18 years and 5 leap days.”
  #
  # See also —
  # - https://medium.com/swlh/should-i-use-date-time-or-datetime-in-ruby-and-rails-9372ad20ca4f
  # - https://stackoverflow.com/questions/11835193/how-do-i-use-ruby-date-constants-gregorian-julian-england-and-even-italy
  #
  # TODO: Figure out how to handle date rollover.
  private def current_raw_gregorian_time = (
    ((::Time::now.utc - ::GlobeGlitter::CHRONO_DIVER::EPOCH_GREGORIAN) *
      ::GlobeGlitter::CHRONO_DIVER::NANOSECONDS_IN_SECOND)             /
      ::GlobeGlitter::CHRONO_DIVER::GREGORIAN_UUID_TICK_RATE
  ).to_i
  def current_gregorian_time = (self.current_raw_gregorian_time % 0xFFFFFFFF_FFFFFFF)  # 60 bits

  # ITU-T Rec. X.667 sez —
  #
  # “[O]btain a 47-bit cryptographic quality random number and use it as the low 47 bits of the node ID,
  #  with the least significant bit of the first octet of the node ID set to one.
  #  This bit is the unicast/multicast bit, which will never be set in IEEE 802 addresses
  #  obtained from network cards.  Hence, there can never be a conflict between UUIDs
  #  generated by machines with and without network cards.”
  private def random_node = (::SecureRandom::random_number(0xFFFFFFFFFFFF) | (0b1 << 40))

  # Get one of our real network interfaces' hardware addresses for use as UUID `node.
  # TOD0: Is there any reason to pick a particular `hwaddr` besides first-enumerated?
  def hardware_node = ::XROSS::THE::NETWORK::interface_addresses.first

  # Fall back to random node ID if a hardware ID is unavailable.
  private def current_node = self.hardware_node || self.random_node

  # ITU-T Rec. X.667 sez —
  #
  #  “For UUID version 1, the clock sequence is used to help avoid
  #   duplicates that could arise when the clock is set backwards in time
  #   or if the node ID changes.
  #
  #   If the clock is set backwards, or might have been set backwards
  #   (e.g., while the system was powered off), and the UUID generator can
  #   not be sure that no UUIDs were generated with timestamps larger than
  #   the value to which the clock was set, then the clock sequence has to
  #   be changed.  If the previous value of the clock sequence is known, it
  #   can just be incremented; otherwise it should be set to a random or
  #   high-quality pseudo-random value.
  #
  #   Similarly, if the node ID changes (e.g., because a network card has
  #   been moved between machines), setting the clock sequence to a random
  #   number minimizes the probability of a duplicate due to slight
  #   differences in the clock settings of the machines.  If the value of
  #   clock sequence associated with the changed node ID were known, then
  #   the clock sequence could just be incremented, but that is unlikely.
  #
  #   The clock sequence MUST be originally (i.e., once in the lifetime of
  #   a system) initialized to a random number to minimize the correlation
  #   across systems.  This provides maximum protection against node
  #   identifiers that may move or switch from system to system rapidly.
  #   The initial value MUST NOT be correlated to the node identifier.”
  def clock_sequence = begin
    # Try to get an actual sequence from the shared source
    ::GlobeGlitter::CHRONO_SEEKER.take
  rescue
    # …but fall back to a random value if something happens to our `::Ractor`
    ::SecureRandom::random_number(0b11111111111111)  # 14 bits
  end

  # TODO: Take arguments to generate identifiers for specific time/seq/node.
  def from_gregorian_time = self::new(
    current_gregorian_time,
    clock_sequence,
    current_node,
    layout: ::GlobeGlitter::LAYOUT_ITU_T_REC_X_667,
    behavior: ::GlobeGlitter::BEHAVIOR_TIME_GREGORIAN,
  )
end

module ::GlobeGlitter::CHRONO_DIVER::FRAGMENT

  # Getters for fields defined in the specification.
  def time_low                    = self.bits127–96
  def time_mid                    = self.bits95–80
  def time_high_and_version       = self.bits79–64
  def clock_seq_high_and_reserved = self.bits63–56 & case self.layout
    # This field is overlayed by the backward-masked `layout` a.k.a. """variant""",
    # so we return a different number of bits from the chunk depending on that value.
    when 0    then 0b01111111
    when 1    then 0b00111111
    when 2, 3 then 0b00011111
    else           0b11111111  # Non-compliant layout. This should never happen.
  end
  def clock_seq_low               =  self.bits55–48
  def node                        =  self.bits47–0

  # Setters for fields defined in the specification.
  def time_low=(otra);  self.bits127–96=(otra); end
  def time_mid=(otra);  self.bits95–80=(otra);  end
  def time_high=(otra); self.bits79–64=(((self >> 64) & 0xF000) | (otra & 0x0FFF)); end
  def time=(otra)
    self.bits79–64=(((self >> 64) & 0x00000000_0000F000) | (otra & 0xFFFFFFFF_FFFF0FFF))
  end
  def clock_seq_high_and_reserved=(otra)
    # This field is overlayed by the backward-masked `layout` a.k.a. """variant""",
    # so we set a different number of bits from the chunk depending on that value
    # along with saving the existing value.
    self.bits63–56=(
      (otra & case self.layout
        when 0    then 0b01111111
        when 1    then 0b00111111
        when 2, 3 then 0b00011111
        else           0b11111111  # Non-compliant layout. This should never happen.
      end) | (case self.layout
        when 0    then 0b00000000
        when 1    then 0b10000000
        when 2    then 0b11000000
        when 3    then 0b11100000
        else           0b00000000  # Non-compliant layout. This should never happen.
      end)
    )
  end
  def clock_seq_low=(otra)
    self.bits55–48=(otra)
  end
  def node=(otra)
    self.bits47–0=(otra)
  end

  # Getter for Base-16 `::String` output where these two fields are combined.
  def clock_seq = (self.clock_seq_high_and_reserved << 8) | self.clock_seq_low
  def clock_seq=(otra)
    self.with(inner_spirit: (
      (self & 0xFFFFFFFF_FFFFFFFF_0000FFFF_FFFFFFFF) |
      (
        case self.layout
          when 0    then 0b00000000
          when 1    then 0b10000000
          when 2    then 0b11000000
          when 3    then 0b11100000
        end << 56
      ) | (otra << 48)
    ))
  end

  # Construct the full timestamp from the split chunk contents.
  #
  # TODO: Support best guess for inner time values which have rolled over,
  #       probably something like enumerating all possibilities and picking
  #       the one with the lowest offset from the current time.
  def time = case self.layout
    when -1 then  self.bits63–28
    when 0  then  self.bits127–80
    when 1  then (self.bits127–96 << 32) | (self.bits95–80 << 16) | (self.bits79–64 & 0x0FFF)
    else nil
  end

  # ITU-T Rec. X.667 sez —
  #
  #  “The timestamp is a 60-bit value.  For UUID version 1, this is
  #   represented by Coordinated Universal Time (UTC) as a count of 100-
  #   nanosecond intervals since 00:00:00.00, 15 October 1582 (the date of
  #   Gregorian reform to the Christian calendar).“
  def to_time
    case [self.layout, self.behavior]
      in [-1, *] then
        ::GlobeGlitter::CHRONO_DIVER::EPOCH_APOLLO + (
          self.time                                            /
          ::GlobeGlitter::CHRONO_DIVER::MILLISECONDS_IN_SECOND *
          ::GlobeGlitter::CHRONO_DIVER::AEGIS_UID_TICK_RATE
        )
      in [0, *]  then
        ::GlobeGlitter::CHRONO_DIVER::EPOCH_APOLLO + (
          self.time                                            /
          ::GlobeGlitter::CHRONO_DIVER::MICROSECONDS_IN_SECOND *
          ::GlobeGlitter::CHRONO_DIVER::NCS_UUID_TICK_RATE
        )
      in [1, 1]  then ::GlobeGlitter::CHRONO_DIVER::EPOCH_GREGORIAN + (
        self.time                                              /
        ::GlobeGlitter::CHRONO_DIVER::NANOSECONDS_IN_SECOND    *
        ::GlobeGlitter::CHRONO_DIVER::GREGORIAN_UUID_TICK_RATE
      )
    else nil
    end
  end

end
