require(-'set') unless defined?(::Set)

require_relative(-'ghost_revival/filter_house') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::ONE_OR_EIGHT)
require_relative(-'ghost_revival/ultravisitor') unless defined?(::CHECKING::YOU::OUT::ULTRAVISITOR)


# IANA Media-Type `String`-handling components.
# CYI class-level components.
module ::CHECKING::YOU::IN::AUSLANDSGESPRÄCH

  # Support compound suffixed type `::String`s à la RFC6839: https://datatracker.ietf.org/doc/html/rfc6839
  #
  # The commented-out items are not supported/needed for our use case,
  # but they are listed here so I can feel confident I didn't forget anything in the RFCs.
  SUFFIX_TYPES = {
    # https://datatracker.ietf.org/doc/html/rfc6839#section-3.2
    #-'ber' => Basic Encoding Rules à la ASN.1 https://datatracker.ietf.org/doc/html/rfc6839#ref-ITU.X690.2008,
    # https://datatracker.ietf.org/doc/html/rfc6839#section-3.3
    #-'der' => Distinguished Encoding Rules https://datatracker.ietf.org/doc/html/rfc6839#ref-ITU.X690.2008,

    # https://datatracker.ietf.org/doc/html/rfc6839#section-3.1
    -'json' => ::CHECKING::YOU::IN::new(:possum, :application, :json).freeze,

    # https://datatracker.ietf.org/doc/html/rfc6839#section-3.4
    -'fastinfoset' => ::CHECKING::YOU::IN::new(:possum, :application, :fastinfoset).freeze,

    # https://datatracker.ietf.org/doc/html/rfc6839#section-3.5
    -'wbxml' => ::CHECKING::YOU::IN::new(:vnd, :application, :"wap.wbxml").freeze,

    # https://datatracker.ietf.org/doc/html/rfc6839#section-3.6
    -'zip' => ::CHECKING::YOU::IN::new(:possum, :application, :zip).freeze,

    # https://datatracker.ietf.org/doc/html/rfc6839#section-3.6
    -'xml' => ::CHECKING::YOU::IN::new(:possum, :application, :xml).freeze,
    -'xml-compressed' => ::Set[
      # This doesn't seem to be a standardized thing, but it's in the fd.o database:
      # https://github.com/w3c/svgwg/issues/701
      ::CHECKING::YOU::IN::new(:possum, :application, :xml).freeze,
      ::CHECKING::YOU::IN::new(:possum, :application, :gzip).freeze,
    ].freeze,

    # Others defined in `freedesktop.org.xml`:
    -'ogg' => ::CHECKING::YOU::IN::new(:possum, :audio, :ogg).freeze,
  }.freeze

  TYPE_SUFFIXES = self::SUFFIX_TYPES.invert.freeze


  # Parse IANA Media-Type `::String` → `::CHECKING::YOU::IN`
  GOLDEN_I = ::Ractor::new(
    ::Ractor::make_shareable(proc {
    # Keep these allocated instead of fragmenting our heap, since this will be called very frequently.
    what_you_doing = ::Array::new
    main_screen    = ::Array::new
    my_base        = ::Array::new
    great_justice  = ::CHECKING::YOU::IN::allocate

    # Clear out the contents of the above temporary vars,
    # called to ensure we never leak the contents of one parse into another.
    the_bomb = proc {
      what_you_doing.clear
      main_screen.clear
      my_base.clear
      great_justice.members.each { |gentleman|
        great_justice[gentleman] = nil
      }
    }

    # Take a single codepoint from a reversed-then-NULL-terminated IANA Type `String`,
    # e.g. "ttub=traf;lmbe+fnb.ppg3.dnv/noitacilppa#{-?\u{0}}".
    #
    #
    # I switched from `String#each_char` to `String#each_codepoint` to avoid allocating single-character `String`s
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
        great_justice[:phylum] = what_you_doing.reverse!.pack(-'U*').to_sym
        my_base.unshift(great_justice.dup)
      when 61 then  # =
        # TODO: Implement Fragment-based Type variations
        main_screen.push(*what_you_doing)
        what_you_doing.clear
      when 59 then  # ;
        # TODO: Implement Fragment-based Type variations
        what_you_doing.clear
        main_screen.clear
      when 43 then  # +
        SUFFIX_TYPES[what_you_doing.reverse!.pack(-'U*')].tap {
          # We could just `my_base.push(*suffix_types)` but that will also decompose `CYIs`
          # to their component `::Symbols` unless we override `CYI#to_a` to `nil`.
          case _1
          in ::Array             => suffix_types then my_base.push(*suffix_types)
          in ::Set               => suffix_types then my_base.push(*suffix_types)
          in ::CHECKING::YOU::IN => suffix_type  then my_base.push(suffix_type)
          else next  # Do nothing.
          end
        }
        what_you_doing.clear
      when 47 then  # /
        # When this character is encountered in a reversed Type String, `what_you_doing` will contain the facet
        # which lets us determine if this Type belongs to a vendor tree, to the e`x`perimental tree, etc.
        great_justice[:kingdom] = case
        when what_you_doing[-3..] == (-'dnv').codepoints then
          what_you_doing.pop(3);
          # https://datatracker.ietf.org/doc/html/rfc6838#section-3.2
          # We will be in a vendor tree, but let's additionally inspect `main_screen` to count its facets.
          # There will be only a single facet for vendor-tree types like `application/vnd.wordperfect`.
          # There will be multiple facets for vendor-tree types like `application/vnd.tcpdump.pcap`.
          #
          # If we have multiple facets, split the (reversed) last facet out and use it as the vendor-tree name,
          # e.g. for `application/vnd/tcpdump.pcap` we will use `tcpdump` as the tree naame instead of `vnd`,
          # in fact not even storing the `vnd` at all.
          #
          # This increases the likelihood of `main_screen`'s remainder fitting inside a single RValue,
          # e.g. for yuge Types like `application/vnd.oasis.opendocument.graphics` we will store `oasis`
          # and `opendocument.graphics` (fits!) instead of `vnd` and `oasis.opendocument.graphics` (doesn't fit!).
          #
          # The dropped `vnd` will be reconstructed by `CYO#to_s` when it detects a non-standard tree name.
          main_screen.rindex(46) ? main_screen.slice!(main_screen.rindex(46)..).reverse!.tap(&:pop).pack(-'U*').to_sym : :vnd
        when what_you_doing[-3..] == (-'srp').codepoints then
          # https://datatracker.ietf.org/doc/html/rfc6838#section-3.3
          # "Media types created experimentally or as part of products that are not distributed commercially".
          # This is mostly an early-Internet legacy and there are only a few of these in `shared-mime-info`,
          # e.g. `audio/prs.sid` for the C=64 Sound Interface Device audio format,
          # but they can still be registered.
          what_you_doing.pop(3); :prs
        when what_you_doing[-5..] == (-'-sm-x').codepoints then
          # Microsoft formats like `text/x-ms-regedit`.
          # I'm treating this separately from the IANA `x-` tree just because there are so many of them,
          # and it's nice to keep Winders formats logically-grouped.
          what_you_doing.pop(5); :"x-ms"
        when what_you_doing[-2..] == (-'-x').codepoints then
          # Deprecated experimental tree (`x-`): https://datatracker.ietf.org/doc/html/rfc6648
          # I'm giving this deprecated tree the canonical `x` tree in CYO because it has legacy dating back
          # to the mid '70s and has many many many more Types than post-2012 `x.` tree,
          # RE: https://datatracker.ietf.org/doc/html/rfc6648#appendix-A
          what_you_doing.pop(2); :x
        when what_you_doing.one? && what_you_doing.last == 120 then  # x
          # Faceted experimental tree (`x.`): https://datatracker.ietf.org/doc/html/rfc6838#section-3.4
          # There are only a few of these since "use of both `x-` and `x.` forms is discouraged",
          # e.g. `model/x.stl-binary`, and there aren't likely to be many more.
          what_you_doing.pop; :"kayo-dot"
        else
          # Otherwise we are in the "standards" tree: https://datatracker.ietf.org/doc/html/rfc6838#section-3.1
          :possum
        end
        # Everything remaining in `main_screen` and `what_you_doing` will comprise the most-specific Type component.
        main_screen.push(*what_you_doing)
        great_justice[:genus] = main_screen.reverse!.pack(-'U*').to_sym
        what_you_doing.clear
        main_screen.clear
      when 46 then  # .
        main_screen << 46 unless main_screen.empty?
        main_screen.push(*what_you_doing)
        what_you_doing.clear
      else
        what_you_doing << zig
      end
    }

    # 𝘐𝘛'𝘚 𝘠𝘖𝘜 !!
    cats = ->(gentlemen) {
      gentlemen.to_s.encode!(::Encoding::UTF_8).each_codepoint.reverse_each(&move_zig)
      move_zig.call(0)
      return my_base.yield_self(
        &::CHECKING::YOU::OUT::GHOST_REVIVAL::ONE_OR_EIGHT
      ).dup.freeze.tap(&the_bomb)
    }
    while message = ::Ractor::receive
      message.in_motion = case message
      when ::CHECKING::YOU::OUT::EverlastingMessage then case cats.call(message.in_motion)
        in ::CHECKING::YOU::IN => cyi  then ::Hash[cyi => ::CHECKING::YOU::OUT::new(*cyi.values)]
        in ::Array             => cyis then
          # Don't freeze.
          ::Hash[
            ::CHECKING::YOU::IN::B4U::new(cyis) => cyis[1...].each_with_object(
              ::CHECKING::YOU::OUT::new(*cyis.first.values)
            ) { _2.add_b4u(_1) }
          ]
        end
      when ::CHECKING::YOU::IN::EverlastingMessage then case cats.call(message.in_motion)
        in ::CHECKING::YOU::IN => cyi  then cyi
        in ::Array             => cyis then ::CHECKING::YOU::IN::B4U::new(cyis)
        end
      end
      message.go_beyond!
    end
  }),
  -'GOLDEN_I',
  name: -'ULTRAVISITOR::GOLDEN_I',
  &::CHECKING::YOU::OUT::ULTRAVISITOR
  )  # GOLDEN_I


  # Calling-`::Ractor`-agnostic `::String`-to-`CYI` method.
  #
  # Normally this is a blocking/synchronous method, but it will immediately return `nil`
  # if the `:receiver` is a `::Ractor` other than the one calling the method.
  # This is kind of hacky but allows e.g. `MIMEjr` to not have to block waiting for our reply
  # only to forward that reply immediately to its real destination.
  def from_iana_media_type(
    ietf_string,
    envelope: ::CHECKING::YOU::IN::EverlastingMessage,
    receiver: ::Ractor::current
  )
    return if ietf_string.nil? or ietf_string&.empty?
    message = envelope.new(ietf_string.dup, receiver)
    wanted = case receiver
    when ::Array then receiver.first == ::Ractor::current
    when ::Ractor::current then true
    else false
    end ? message.erosion_mark : nil
    GOLDEN_I.send(message, move: true)
    ::Ractor::receive_if {
      _1.is_a?(::CHECKING::YOU::IN::EverlastingMessage) and _1.erosion_mark == wanted
    }.in_motion if wanted
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
    :chemical,            # Non-IANA Chemical MIME project: https://www.ch.ic.ac.uk/chemime/
    :example,
    :font,                # RFC 8081: https://datatracker.ietf.org/doc/html/rfc8081
    :image,
    :inode,               # `shared-mime-info` irregular-file types.
    :message,
    :model,               # RFC 2077: https://datatracker.ietf.org/doc/html/rfc2077
    :multipart,
    :text,
    :video,
    :"x-scheme-handler",  # `shared-mime-info` URL-scheme types.
    :"x-content",         # `shared-mime-info` directory/volume types.
  ].freeze

  # Reconstruct an IANA Media-Type `String` from a loaded CYI/CYO's `#members`
  # This method should return an unfrozen `String` because `CYO#to_s` may add a suffix to it.
  def say_yeeeahh
    # TODO: Fragments (e.g. `;what=ever`), and syntax identifiers (e.g. `+xml`)
    (::String.new(encoding: ::Encoding::UTF_8, capacity: 128) << self.phylum.to_s << -'/' << case
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

  # Since there are no CYI suffixes we can just return the frozen `String`.
  def to_s; -say_yeeeahh; end

  # Pretty-print objects using our custom `#:to_s`
  def inspect; "#<#{self.class.to_s} #{self.to_s}>"; end
end


# Class-level method to fetch a CYO from a `::Ractor` area.
module ::CHECKING::YOU::OUT::AUSLANDSGESPRÄCH
  def from_iana_media_type(ietf_string, area_code: ::CHECKING::YOU::IN::DEFAULT_AREA_CODE)
    super(
      ietf_string,
      receiver: ::Ractor::make_shareable(
        ::Array[::Ractor::current, ::CHECKING::YOU::OUT::GHOST_REVIVAL::AREAS.call(area_code)]
      )
    )
  end
end

# Instance-level method to generate the full IANA Media-Type `::String` of composite types,
# e.g. `"image/svg+xml"`.
module ::CHECKING::YOU::OUT::INLANDGESPRÄCH
  def to_s
    self.say_yeeeahh << case ::CHECKING::YOU::IN::AUSLANDSGESPRÄCH::TYPE_SUFFIXES[self.b4u]
      in ::NilClass then nil.to_s
      in ::String => suffix then ?+ << suffix
    end.to_s.-@
  end
end

# Instance-level components to pretty-print our multi-CYI `Set` subclass.
module ::CHECKING::YOU::IN::B4U::INLANDGESPRÄCH
  def to_s
    self.first.say_yeeeahh << case ::CHECKING::YOU::IN::AUSLANDSGESPRÄCH::TYPE_SUFFIXES[
      self.to_a[1...].to_set.yield_self(&::CHECKING::YOU::OUT::GHOST_REVIVAL::ONE_OR_EIGHT)
    ]
      in ::NilClass then nil.to_s
      in ::String => suffix then ?+ << suffix
    end.to_s.-@
  end
  def inspect; "#<#{self.class.to_s} #{self.to_s}>"; end
end
