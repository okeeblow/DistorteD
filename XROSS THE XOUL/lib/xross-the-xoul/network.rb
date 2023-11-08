class XROSS; end
class XROSS::THE; end
# General background info: https://beej.us/guide/bgnet/html/
class XROSS::THE::NETWORK

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
  # …but there seems to be no way to get the raw 48-bit value in Ruby code without parsing the `::String` output
  # of `::Addrinfo#inspect`, confirmed when we look at `raddrinfo.c` and see it constructing a `str`:
  # https://github.com/ruby/ruby/blob/ea8a7287e2b96b9c24e5e89fe863e5bfa60bfdda/ext/socket/raddrinfo.c#L1375
  #
  # MAYBE: Figure out how to use ioctl to get this without `::String` parsing.
  # - https://stackoverflow.com/a/1779758
  # - https://medium.com/geckoboard-under-the-hood/how-to-build-a-network-stack-in-ruby-f73aeb1b661b
  MATCH_INTERFACE_HWADDR = /hwaddr=(?<hwaddr>\h\h:\h\h:\h\h:\h\h:\h\h:\h\h)/

  # Get 48-bit `::Integer` value of our 802.3 network interface addresses, minus any loopback interfaces.
  # NOTE: Can return an empty `::Array`!
  def self.interface_addresses = ::Socket::getifaddrs.map!(&:addr).map!(&:inspect_sockaddr).map! {
    # Using `::MatchData#[]` in favor of `::MatchData#captures` because `#captures`
    # allocates a new `::Array` and we only care about a single match.
    # See https://github.com/ruby/ruby/blob/master/re.c CTRL+F `match_array`
    _1.match(MATCH_INTERFACE_HWADDR)&.[](1)&.delete!(?:)&.to_i(16)
  }.compact.tap {
    # There can be multiple loopback interfaces or no loopback interface.
    # Since we have `#compact`ed, a single `#delete` will delete any and all of the same `hwaddr`.
    _1.delete(0)
  }

end
