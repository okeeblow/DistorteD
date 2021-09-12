# IETF Media-Type `String`-handling components.
# CYI class-level components.
module ::CHECKING::YOU::IN::AUSLANDSGESPRÄCH

  # Parse IETF Media-Type String → `::CHECKING::YOU::IN`
  FROM_IETF_TYPE = ::Ractor.make_shareable(proc {
    # Keep these allocated instead of fragmenting our heap, since this will be called very frequently.
    scratch = ::Array.allocate
    hold    = ::Array.allocate
    my_base = ::CHECKING::YOU::IN::allocate

    # Clear out the contents of the above temporary vars,
    # called to ensure we never leak the contents of one parse into another.
    the_bomb = proc {
      scratch.clear
      hold.clear
      my_base.members.each { |gentleman|
        my_base[gentleman] = nil
      }
    }

    # Take a single codepoint from a reversed-then-NULL-terminated IETF Type String,
    # e.g. "ttub=traf;lmbe+fnb.ppg3.dnv/noitacilppa#{-?\u{0}}".
    #
    #
    # I switched from `String#each_char` to `String#each_codepoint` to avoid allocating single-character Strings
    # before they could be deduplicated with `-zig`. The Integer codepoints, on the other hand,
    # will always be the same `object_id` for the same codepoint:
    #
    # rb(main):162:0> -"あああ".each_char { |c| p c.object_id }
    # 420
    # 440
    # 460
    #
    # rb(main):163:0> -"あああ".each_codepoint { |c| p c.object_id }
    # 4709
    # 4709
    # 4709
    #
    #
    # Putting the codepoints back together with `Array#pack` is the fastest way I've found,
    # but it is mildly annoying that it won't intern the packed Strings in the C `pack_pack` code,
    # which lives here: https://github.com/ruby/ruby/blob/master/pack.c
    #
    # This means that interning them here in Ruby-land forces us to eat the spurious allocation
    # and is generally slower than it needs to be, e.g. `memory_profiler` report without post-allocation interning:
    #
    #   Retained String Report
    #   -----------------------------------
    #       1038  "application"
    #       1037  <internal:pack>:135
    #
    #        171  "text"
    #        170  <internal:pack>:135
    #
    #        140  "image"
    #        139  <internal:pack>:135
    #   […]
    #   -----------------------------------
    #
    # …vs `memory_profiler` report *with* post-allocation interning, where the duplicate packed Strings
    # are now "Allocated" instead of "Retained", i.e. they will be GCed:
    #
    #   Allocated String Report
    #   -----------------------------------
    #       2863  ""
    #       2818  /home/okeeblow/Works/DistorteD/CHECKING-YOU-OUT/lib/checking-you-out/party_starter.rb:90
    #
    #       2271  "application"
    #       2269  <internal:pack>:135
    #   […]
    #   -----------------------------------
    #
    # This ends up being a difference of ~2000 Objects for us, comparing the same before/after as above:
    #
    #   [okeeblow@emi#CHECKING-YOU-OUT] ./bin/are-we-unallocated-yet|grep Total
    #   Total allocated: 18178861 bytes (318640 objects)
    #   Total retained:  1999675 bytes (26815 objects)
    #   [okeeblow@emi#CHECKING-YOU-OUT] ./bin/are-we-unallocated-yet|grep Total
    #   Total allocated: 18231779 bytes (319963 objects)
    #   Total retained:  1926675 bytes (24996 objects)
    move_zig = proc { |zig|
      case zig
      when 0 then  # NULL
        my_base[:phylum] = scratch.reverse!.pack(-'U*').to_sym
      when 61 then  # =
        # TODO: Implement Fragment-based Type variations
        hold.push(*scratch)
        scratch.clear
      when 59 then  # ;
        # TODO: Implement Fragment-based Type variations
        scratch.clear
        hold.clear
      when 43 then  # +
        #TODO: Implement tagged parent Types e.g. `+xml`
        scratch.clear
      when 47 then  # /
        # When this character is encountered in a reversed Type String, `scratch` will contain the facet
        # which lets us determine if this Type belongs to a vendor tree, to the e`x`perimental tree, etc.
        my_base[:kingdom] = case
        when scratch[-3..] == (-'dnv').codepoints then
          scratch.pop(3);
          # https://datatracker.ietf.org/doc/html/rfc6838#section-3.2
          # We will be in a vendor tree, but let's additionally inspect `hold` to count its facets.
          # There will be only a single facet for vendor-tree types like `application/vnd.wordperfect`.
          # There will be multiple facets for vendor-tree types like `application/vnd.tcpdump.pcap`.
          #
          # If we have multiple facets, split the (reversed) last facet out and use it as the vendor-tree name,
          # e.g. for `application/vnd/tcpdump.pcap` we will use `tcpdump` as the tree naame instead of `vnd`,
          # in fact not even storing the `vnd` at all.
          #
          # This increases the likelihood of `hold`'s remainder fitting inside a single RValue,
          # e.g. for yuge Types like `application/vnd.oasis.opendocument.graphics` we will store `oasis`
          # and `opendocument.graphics` (fits!) instead of `vnd` and `oasis.opendocument.graphics` (doesn't fit!).
          #
          # The dropped `vnd` will be reconstructed by `CYO#to_s` when it detects a non-standard tree name.
          hold.rindex(46) ? hold.slice!(hold.rindex(46)..).reverse!.tap(&:pop).pack(-'U*').to_sym : :vnd
        when scratch[-3..] == (-'srp').codepoints then
          # https://datatracker.ietf.org/doc/html/rfc6838#section-3.3
          # "Media types created experimentally or as part of products that are not distributed commercially".
          # This is mostly an early-Internet legacy and there are only a few of these in `shared-mime-info`,
          # e.g. `audio/prs.sid` for the C=64 Sound Interface Device audio format,
          # but they can still be registered.
          scratch.pop(3); :prs
        when scratch[-5..] == (-'-sm-x').codepoints then
          # Microsoft formats like `text/x-ms-regedit`.
          # I'm treating this separately from the IETF `x-` tree just because there are so many of them,
          # and it's nice to keep Winders formats logically-grouped.
          scratch.pop(5); :"x-ms"
        when scratch[-2..] == (-'-x').codepoints then
          # Deprecated experimental tree (`x-`): https://datatracker.ietf.org/doc/html/rfc6648
          # I'm giving this deprecated tree the canonical `x` tree in CYO because it has legacy dating back
          # to the mid '70s and has many many many more Types than post-2012 `x.` tree,
          # RE: https://datatracker.ietf.org/doc/html/rfc6648#appendix-A
          scratch.pop(2); :x
        when scratch.one? && scratch.last == 100 then  # x
          # Faceted experimental tree (`x.`): https://datatracker.ietf.org/doc/html/rfc6838#section-3.4
          # There are only a few of these since "use of both `x-` and `x.` forms is discouraged",
          # e.g. `model/x.stl-binary`, and there aren't likely to be many more.
          scratch.pop; :"kayo-dot"
        else
          # Otherwise we are in the "standards" tree: https://datatracker.ietf.org/doc/html/rfc6838#section-3.1
          :possum
        end
        # Everything remaining in `hold` and `scratch` will comprise the most-specific Type component.
        hold.push(*scratch)
        my_base[:genus] = hold.reverse!.pack(-'U*').to_sym
        scratch.clear
        hold.clear
      when 46 then  # .
        hold << 46 unless hold.empty?
        hold.push(*scratch)
        scratch.clear
      else
        scratch << zig
      end
    }

    # 𝘐𝘛'𝘚 𝘠𝘖𝘜 !!
    cats = ->(gentlemen) {
      gentlemen.each_codepoint.reverse_each(&move_zig)
      move_zig.call(0)
      return my_base.dup.freeze.tap(&the_bomb)
    }
    -> (gentlemen) {
      return cats.call((gentlemen.encoding == ::Encoding::UTF_8) ? gentlemen : gentlemen.encode(::Encoding::UTF_8))
    }
  })

  # Call the above singleton Proc to do the thing.
  def from_ietf_media_type(ietf_string)
    return if ietf_string.nil?
    # `#to_s` is a no-op for `String`s, so make sure we call it to support `Symbol`s and other input types here.
    #   irb> oid = proc { p "#{_1} is object_id #{_1.object_id}" } => #<Proc:0x00005640ef7b0440 (irb):7>
    #   irb> 'lol'.tap(&oid).to_s.tap(&oid)
    #   "lol is object_id 1340"
    #   "lol is object_id 1340"
    #
    # This parser will be initialized in the class namespace of the main `Ractor`
    # and should not be touched from `area` `Ractor`s.
    (@ietf_parser ||= FROM_IETF_TYPE.call).call(ietf_string.to_s)
  end
end


# CYI instance-level components.
module ::CHECKING::YOU::IN::INLANDGESPRÄCH
  # An unknown primary-type as a `CY(I|O)`'s `:kingdom` signifies the need for
  # a leading `vnd.` facet when reconstructing the Media-Type `String`.
  PRIMARY_CONTENT_TYPES = [
    # Current top-level IANA registries are shown here: https://www.iana.org/assignments/media-types/media-types.xhtml
    :application,
    :audio,
    :chemical,     # Non-IANA Chemical MIME project: https://www.ch.ic.ac.uk/chemime/
    :example,
    :font,         # RFC 8081: https://datatracker.ietf.org/doc/html/rfc8081
    :image,
    :message,
    :model,        # RFC 2077: https://datatracker.ietf.org/doc/html/rfc2077
    :multipart,
    :text,
    :video,
  ].freeze

  # Reconstruct an IETF Media-Type String from a loaded CYI/CYO's `#members`
  def to_s
    # TODO: Fragments (e.g. `;what=ever`), and syntax identifiers (e.g. `+xml`)
    -(::String.new(encoding: ::Encoding::UTF_8, capacity: 128) << self.phylum.to_s << -'/' << case
    when self.kingdom == :"kayo-dot" then -'x.'
    when self.kingdom == :x then -'x-'
    when self.kingdom == :"x-ms" then -'x-ms-'
    when self.kingdom == :prs then -'prs.'
    when self.kingdom == :vnd then -'vnd.'
    when self.kingdom == :possum then nil.to_s
    when !PRIMARY_CONTENT_TYPES.include?(self.kingdom.to_s) then 'vnd.' << self.kingdom.to_s << -'.'
    else self.kingdom.to_s << -'.'
    end << self.genus.to_s)
  end

  # Pretty-print objects using our custom `#:to_s`
  def inspect; "#<#{self.class.to_s} #{self.to_s}>"; end
end


# CYO class-level components.
module CHECKING::YOU::OUT::AUSLANDSGESPRÄCH
  # Return a `::CHECKING::YOU::OUT` object from a given `::Ractor` pool.
  def from_ietf_media_type(ietf_string, area_code: self.superclass::DEFAULT_AREA_CODE)
    return if ietf_string.nil?
    self.areas[area_code].send(
      ::CHECKING::YOU::OUT::GHOST_REVIVAL::EverlastingMessage.new(::Ractor.current, -ietf_string),
      move: true,
    )
    ::Ractor.receive_if { |msg|
      msg.is_a?(::CHECKING::YOU::OUT::GHOST_REVIVAL::EverlastingMessage) and msg.request == ietf_string
    }.response
  end
end
