require('securerandom') unless defined?(::SecureRandom)
require('socket') unless defined?(::Socket)

# Components for time-based UUIDs.
#
# See also:
# - https://pythonhosted.org/time-uuid/
module ::GlobeGlitter::CHRONO_DIVER; end
module ::GlobeGlitter::CHRONO_DIVER::PENDULUMS

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
  private def current_time = (((::Time::now.utc - ::Time::new(1582, 10, 15)) * 1_000_000_000) / 100).to_i

  # ITU-T Rec. X.667 sez —
  #
  # “[O]btain a 47-bit cryptographic quality random number and use it as the low 47 bits of the node ID,
  #  with the least significant bit of the first octet of the node ID set to one.
  #  This bit is the unicast/multicast bit, which will never be set in IEEE 802 addresses
  #  obtained from network cards.  Hence, there can never be a conflict between UUIDs
  #  generated by machines with and without network cards.”
  private def random_node = (::SecureRandom::random_number(0xFFFFFFFFFFFF) | (0b1 << 40))

  # General background info: https://beej.us/guide/bgnet/html/
  #
  # Ruby exposes `hwaddr` in `::Socket::getifaddrs`, e.g. —
  #
  # irb> Socket::getifaddrs.map(&:addr)
  # => 
  # [#<Addrinfo: PACKET[protocol=0 lo hatype=772 HOST hwaddr=00:00:00:00:00:00]>,
  #  #<Addrinfo: PACKET[protocol=0 enp1s0 hatype=1 HOST hwaddr=00:e0:4c:18:42:69]>,
  #  #<Addrinfo: PACKET[protocol=0 wlp2s0 hatype=1 HOST hwaddr=80:19:34:6f:13:37]>,
  #  #<Addrinfo: 127.0.0.1>,
  #  #<Addrinfo: 172.16.0.226>,
  #  #<Addrinfo: 172.16.0.88>,
  #  #<Addrinfo: ::1>,
  #  #<Addrinfo: fe80::d9d7:4890:9ebc:486%wlp2s0>]
  #
  # …but there seems to be no way to get it in Ruby code without parsing the `::String` output
  # of `::Addrinfo#inspect`, confirmed when we look at `raddrinfo.c` and see it constructing a `str`:
  # https://github.com/ruby/ruby/blob/ea8a7287e2b96b9c24e5e89fe863e5bfa60bfdda/ext/socket/raddrinfo.c#L1375
  #
  # MAYBE: Figure out how to use ioctl to get this without `::String` parsing.
  # - https://stackoverflow.com/a/1779758
  # - https://medium.com/geckoboard-under-the-hood/how-to-build-a-network-stack-in-ruby-f73aeb1b661b
  private def hardware_node = ::Socket::getifaddrs.map(&:addr).map(&:inspect_sockaddr).map! {
    _1.match(/hwaddr=(?<hwaddr>\h\h:\h\h:\h\h:\h\h:\h\h:\h\h)/)&.captures&.pop&.gsub(?:, '')&.to_i(16)
  }.compact.tap {
    # Remove `00:00:00:00:00:00` loopback address.
    # TODO: Better logic. There can be multiple loopback interfaces or no loopback interface.
    #       Maybe alter the `::Regexp` above and remove this `tap`/`delete` section entirely.
    _1.delete(0)
  }&.max {
    # Choose the hwaddr that gives up the most entropy for a UUID,
    # rather than always the first-enumerated hwaddr.
    _1.bit_length
  }

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
  #
  # TODO: Pick a single random sequence at startup and increment from there,
  #       maybe in a dedicated `::Ractor`.
  def clock_sequence = ::SecureRandom::random_number(0xFFFF)

  # TODO: Take arguments to generate identifiers for specific time/seq/node.
  def from_time = self::new(
    current_time,
    clock_sequence,
    current_node,
    structure: ::GlobeGlitter::STRUCTURE_ITU_T_REC_X_667,
    rules: ::GlobeGlitter::RULES_TIME_GREGORIAN,
  )
end

module ::GlobeGlitter::CHRONO_DIVER::FRAGMENT

  # Getters for fields defined in the specification.
  def time_low                    = self.bits127–96
  def time_mid                    = self.bits95–80
  def time_high_and_version       = self.bits79–64
  def clock_seq_high_and_reserved = self.bits63–56 & case self.structure
    # This field is overlayed by the backward-masked `structure` a.k.a. """variant""",
    # so we return a different number of bits from the chunk depending on that value.
    when 0    then 0b01111111
    when 1    then 0b00111111
    when 2, 3 then 0b00011111
    else           0b11111111  # Non-compliant structure. This should never happen.
  end
  def clock_seq_low               =  self.bits55–48
  def node                        =  self.bits47–0

  # Setters for fields defined in the specification.
  def time_low=(otra);  self.bits127–96=(otra); end
  def time_mid=(otra);  self.bits95–80=(otra);  end
  def time_high=(otra); self.bits79–64=(((self.inner_spirit >> 64) & 0xF000) | (otra & 0x0FFF)); end
  def time=(otra)
    self.bits79–64=(((self.inner_spirit >> 64) & 0x00000000_0000F000) | (otra & 0xFFFFFFFF_FFFF0FFF))
  end
  def clock_seq_high_and_reserved=(otra)
    # This field is overlayed by the backward-masked `structure` a.k.a. """variant""",
    # so we set a different number of bits from the chunk depending on that value
    # along with saving the existing value.
    self.bits63–56=(
      (otra & case self.structure
        when 0    then 0b01111111
        when 1    then 0b00111111
        when 2, 3 then 0b00011111
        else           0b11111111  # Non-compliant structure. This should never happen.
      end) | (case self.structure
        when 0    then 0b00000000
        when 1    then 0b10000000
        when 2    then 0b11000000
        when 3    then 0b11100000
        else           0b00000000  # Non-compliant structure. This should never happen.
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

  # Construct the full timestamp from the split chunk contents.
  def time = (self.bits127–96 << 32) | (self.bits95–80 << 16) | (self.bits79–64 & 0x0FFF)

  # ITU-T Rec. X.667 sez —
  #
  #  “The timestamp is a 60-bit value.  For UUID version 1, this is
  #   represented by Coordinated Universal Time (UTC) as a count of 100-
  #   nanosecond intervals since 00:00:00.00, 15 October 1582 (the date of
  #   Gregorian reform to the Christian calendar).“
  def to_time = ::Time::new(1582, 10, 15).utc + (self.time / 10000000)

end
