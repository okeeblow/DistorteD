require(-'file') unless defined?(::File)
require(-'pathname') unless defined?(::Pathname)
require(-'set') unless defined?(::Set)

# https://github.com/jarib/ffi-xattr
require(-'ffi-xattr') unless defined?(::Xattr)

# Assorted specialty data structure classes / modules for storing loaded type data in-memory in a usable way.
require_relative(-'ghost_revival/set_me_free') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::SET_ME_FREE)
require_relative(-'ghost_revival/stick_around') unless defined?(::CHECKING::YOU::OUT::StickAround)
require_relative(-'ghost_revival/weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)
require_relative(-'ghost_revival/wild_io') unless defined?(::CHECKING::YOU::OUT::Wild_I∕O)

# Components for locating `shared-mime-info` XML packages system-wide and locally to CYO.
require_relative(-'ghost_revival/discover_the_life') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::SharedMIMEinfo)
require_relative(-'ghost_revival/xross_infection') unless defined?(::CHECKING::YOU::OUT::XROSS_INFECTION)

# Actual `shared-mime-info` parsers.
require_relative(-'ghost_revival/mime_jr') unless defined?(::CHECKING::YOU::OUT::MIMEjr)
require_relative(-'ghost_revival/mr_mime') unless defined?(::CHECKING::YOU::OUT::MrMIME)

# Decision-making matrix for various combinations of filename- and content-matches.
require_relative(-'ghost_revival/magic_has_the_right_to_children') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::MAGIC_CHILDREN)


# This module contains the core data-loading components for turning source data into usable in-memory structures
# and performing matching between those structures and user-given `::Pathname` or `IO`-like objects.
#
# NOTE: This interface is likely to change as I `Ractor`-ize the rest of DistorteD!
#       Right now it basically emulates the old synchronous method interface with
#       blocking `::Ractor.take` calls which really provides zero benefit at all
#       in that programming model over non-`Ractor`-ized CYO :)
#
#       The interface methods are very serial for now and will be refactored to better handle
#       things like preloading of several types at once from a DistorteD Lens.
#
#       In fact `Ractor`-ization took CYO in my synthetic benchmark from being the fastest
#       file-typing library to being the slowest, but that's Not The Point™
module ::CHECKING::YOU::IN::GHOST_REVIVAL

  # We will remember our computed answer to a configurable number of recently-seen needles
  # (e.g. `::Pathname`s or `:IO` streams) for performance, especially with unmatchable needles.
  DEFAULT_CACHE_SIZE = 111.freeze

  # Memoization `::Hash` for all running CYO `::Ractor`s!
  # Keyed on the area name, usually the value in `DEFAULT_AREA_CODE`.
  def areas
    @areas ||= ::Hash.new { |areas, area_code|
      # Create a new `::Ractor` CYO container and `#send` it every available MIME-info XML package.
      areas[area_code] =
        discover_fdo_xml
          .each_with_object(self.new_area(area_code: area_code)) { |xml_path, area|
            area.send(xml_path)
          }
    }
  end


  # Never return empty `::Enumerable`s.
  # Yielding-self to this proc will `nil`-ify anything that's `:empty?`
  # and will pass any non-`::Enumerable` `::Object`s through.
  POINT_ZERO = ::Ractor.make_shareable(proc { _1.respond_to?(:empty?) ? (_1.empty? ? nil : _1) : _1 })

  # Never `::Enumerable`s with fewer than two members.
  # Yielding-self to this proc will `nil`-ify anything that's `#size` >= 2
  # and will pass any non-Enumerable Objects through.
  XANADU_OF_TWO = ::Ractor.make_shareable(proc { _1.respond_to?(:size) ? (_1.size >= 2 ? _1 : nil) : _1 })

  # Our matching block will return a single CYO when possible, and can optionally
  # return multiple CYO matches for ambiguous files/streams.
  # Multiple matching must be opted into with `only_one_match: false` so it doesn't need to be
  # checked by every caller that's is fine with best-effort and wants to minimize allocations.
  ONE_OR_EIGHT = ::Ractor.make_shareable(proc { |huh|
    case
    when huh.nil? then nil
    when huh.respond_to?(:empty?), huh.respond_to?(:first?)
      if huh.empty? then nil
      elsif huh.size == 1 then huh.is_a?(::Hash) ? huh.values.first : huh.first
      else huh
      end
    else huh
    end
  })


  # Check the filesystem extended attributes for manually-defined types.
  #
  # These should contain IETF-style `media/sub`-type Strings,
  # but they are technically freeform and must be assumed to contain anything.
  # It's very very unlikely that anybody will ever use one of these at all,
  # but hey how cool is it that we will support it if they do? :)
  #
  # T0DO: Figure out if NTFS has anything to offer us since `ffi-xattr` does support Winders.
  # https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fscc/a82e9105-2405-4e37-b2c3-28c773902d85
  #
  # TODO: Re-write this to make it work in `Ractor`-land. This is currently broken.
  #       Possibly using `::Fiddle` in stdlib?
  EXTEND_JOY = ::Ractor.make_shareable(proc { |pathname|
    ::Xattr.new(pathname).to_h.slice(
      # The freedesktop-dot-org specification is `user.mime_type`:
      # https://www.freedesktop.org/wiki/CommonExtendedAttributes/
      -'user.mime_type',
      # At least one other application I can find (lighttpd a.k.a. "lighty")
      # will use `Content-Type` just like would be found in an HTTP header:
      # https://redmine.lighttpd.net/projects/1/wiki/Mimetype_use-xattrDetails
      -'Content-Type',
    )
  })


  # Construct a `Ractor` container for a single area of type data, chosen by the `area_code` parameter.
  # This allows separate areas for separate services/workflows running within the same Ruby interpreter.
  def new_area(area_code: DEFAULT_AREA_CODE)
    # `::Ractor.new` won't take arbitrary named arguments, just positional.
    ::Ractor.new(::Ractor.current, max_burning = DEFAULT_CACHE_SIZE, name: area_code) { |golden_i, max_burning|

      # These `::Hash` sub-classes needs to be defined in the `::Ractor` scope because the block argument to `:define_method`
      # is un-shareable, otherwise trying to `:merge` or `:bury` results in a `defined in a different Ractor (RuntimeError)`:
      # - https://bugs.ruby-lang.org/issues/17722 
      # - https://github.com/ruby/ruby/pull/4771/commits/b92c26a56fb515c9225cfd11e965abffe583e0a5
      set_me_free         = self.instance_eval(&SET_ME_FREE)
      magic_without_tears = self.instance_eval(&::CHECKING::YOU::OUT::SweetSweet♡Magic::MAGIC_WITHOUT_TEARS)


      # Instances of the above classes to hold our type data.
      all_night     = set_me_free.new          # Main `{CYI => CYO}` container.
      postfixes     = set_me_free.new          # `{StickAround => CYO}` container for Postfixes (extnames).
      globs         = set_me_free.new          # `{StickAround => CYO}` container for more complex filename globs.
      as_above      = magic_without_tears.new  # `{offsets => (Speedy|Sequence)Cat` => CYO}` container for content matching.
      ietf_parser   = ::CHECKING::YOU::IN::AUSLANDSGESPRÄCH::FROM_IETF_TYPE.call  # Parse `String`s into `CYI`s.


      # Two-step `shared-mime-info` XML parsers.
      # `Ractor`-ized CYO supports partial loading of type data à la `mini_mime` to conserve memory
      # and minimize object allocations (formerly ~18k objects to load the entire fd.o set vs ~3k for a basic set now).
      #
      # It isn't as simple as parsing the XML against a given `Pathname`/`IO` on the fly and returning
      # the matching CYO objects as they are parsed, because a single type's definition can be spread out
      # over any number of XML package files. We may have passed by and discarded parts of a type by the time
      # we get to the XML package having a positive filename or content match.
      # The `shared-mime-info` format also allows XML packages to alter/delete the content loaded from previously-
      # parsed packages, e.g. with the `<glob-deleteall>` and the `<magic-deleteall>` elements.
      #
      # To support this I split the XML parser into two parts.
      # - The first parser takes a `Pathname` or `IO`-like stream (e.g. from `File.open`), performs on-the-fly-but-partial
      #   filename and content matching, and returns `CHECKING::YOU::IN` key `Struct`s of any matched types.
      # - The second parser takes `CHECKING::YOU::IN` (or a `String` or `Regexp`!) objects and does the traditional full
      #   build of `CHECKING::YOU::OUT` type objects from all available XML package files, even those which do not define
      #   the filename globs or content byte sequences that were matched!
      mr_mime       = ::CHECKING::YOU::OUT::MrMIME::new(::CHECKING::YOU::IN)  # …and `CYI` => `CYO`.
      mime_jr       = ::CHECKING::YOU::OUT::MIMEjr::new(Wild_I∕O, receiver: mr_mime)  # `Pathname`/`IO` => `CYI`


      # Memoize a single new `::CHECKING::YOU::OUT` type instance.
      remember_me   = proc { |cyo|
        # Main memoization `Hash` keyed by `CYI`.
        all_night.bury(cyo.in, cyo)

        # Memoize single-extname "postfixes" separately from more complex filename globs
        # to allow work and record-keeping with pure extnames.
        postfixes.bury(cyo.postfixes, cyo)
        globs.bury(cyo.globs, cyo)

        # Memoize content-match byte sequences in nested `Hash`es based on the starting and ending
        # byte offset where each byte sequence may be found in a hypothetical file/stream.
        case cyo.cat_sequence
        when ::NilClass then next
        when ::Set then
          cyo.cat_sequence&.each { |action| as_above.bury(action.min, action.max, action, cyo) }
        else
          as_above.bury(cyo.cat_sequence.min, cyo.cat_sequence.max, cyo.cat_sequence, cyo)
        end
      }

      # Return the best guess for a given needle's type based on our currently-loaded data.
      # A return value of `nil` here will trigger a `SharedMIMEinfo` XML package search
      # the first time that needle is seen (or if it has been purged from our cache).
      remember_you  = proc { |needle|
        case needle
        when ::CHECKING::YOU::OUT::StickAround then globs[needle] || postfixes[needle]
        when ::CHECKING::YOU::IN::GHOST_REVIVAL::Wild_I∕O then
          # "If a MIME type is provided explicitly (eg, by a ContentType HTTP header, a MIME email attachment,
          #  an extended attribute or some other means) then that should be used instead of guessing."
          # This will probably always be `nil` since this is a niche feature, but we have to test it first.
          # TODO: Find/write some kind of xattr support that works in `::Ractor`-land.
          xattr = nil#EXTEND_JOY.call(needle).values.map(&ietf_parser.method(:call))
          unless xattr.nil? or xattr&.empty? then xattr.first
          else
            ::CHECKING::YOU::IN::GHOST_REVIVAL::MAGIC_CHILDREN.call(
              (globs[needle.stick_around] || postfixes[needle.stick_around]),
              as_above.so_below(needle.stream),
            )
          end
        when ::String then
          # This kinda sucks because it will allocate increasingly more `::String`s as we load type data.
          all_night.values.lazy.select { ::File.fnmatch?(needle, _1.to_s) }.to_set.yield_self(
            # If the needle `::String` contains a wildcard (`*` character) we must return `nil`
            # unless we match two or more types.
            # This is the simplest defense against returning poor results for wildcard queries
            # when we have already loaded some matching types,
            # e.g. if we load just `"image/jpeg"` but then try to match `"image/*"`.
            #
            # T0DO: The possibility of an incomplete match still exists here!
            #       All it would take it pre-loading more than one matching type.
            #       It might be better to explicitly XML-parse when we get wildcard needles.
            &(needle.include?(-?*) ? XANADU_OF_TWO : ONE_OR_EIGHT)
          )
        end  # case needle
      }

      # Cache recent results to minimize denial-of-service risk if we get sent an unmatchable message in a loop.
      # Use a `Hash` to store the last return value for a configurable number of previous query messages.
      # Use `Thread::Queue` to handle cache eviction of oldest keys from the `Hash`.
      last_message = ::Hash.new
      refrain      = ::Thread::Queue.new

      # Remember the destination `::Ractor` for every needle which isn't immediately matched.
      # An uncached unmatchable needle will trigger the `MIMEjr` → `MrMIME` → `self` parsing loop,
      # then we will try matching the needle again and send the result to the `::Ractor` recorded here
      # even if that result is `nil`.
      #
      # The destination `::Ractor` will be blocking on `::Ractor.receive` until we send something,
      # so a `nil` result can still be important :)
      #
      # Key on the needle's `#hash` (i.e. `::Integer` => `::Ractor`) instead of the needle `::Object` itself,
      # because we will lose access to the real `::Object` after `::Ractor.send(move: true)`-ing it.
      #
      # TODO: All of the `#values` here will be `golden_i` (the `::Ractor` who created our `::Ractor`) for now
      #       until I come up with some structure to specify the intended receiver `::Ractor` for a query.
      #       I avoided doing that for now to avoid both:
      #         - the extra allocation necessary to wrap every message since `#send` only takes one argument.
      #         - the complexity of handling both wrapped and unwrapped messages.
      #       idk if it's possible to avoid both of them forever lol
      promise_for_life = ::Hash.new


      # Main message loop to process incoming `::Ractor` message queue for instructions.
      # This will block when the queue empties.
      while message = ::Ractor.receive

        # Return a cached value if we have one, and short-circuit the entire rest of processing this message.
        # The cached value can be `nil`, a single CYO, or an `::Enumerable` (e.g. for `::Regexp` needles).
        unless message.is_a?(::CHECKING::YOU::OUT::BatonPass) then
        if last_message.has_key?(message.hash) then
          # TODO: Support specifying receiver `::Ractor` here (see comment on `promise_for_life`).
          golden_i.send(last_message[message.hash], move: ::Ractor.shareable?(last_message[message.hash]))
          next
        end
        end

        # HACK: Wrap `::Pathname` needle messages into our own `::Struct` so we can pass around
        #       the `::Pathname` itself, its `::IO` stream (from `::Pathname#open` iff extant file),
        #       and its `::StickAround` all as a single unit.
        #
        # T0DO: If I can get `::Pathname`s to match completely against `::StickAround` `::Hash` keys
        #       then I'd like to avoid an extra allocation by killing the `::Struct`,
        #       subclassing `::Pathname` itself, and keeping the stream around as an IVar.
        #       Then I could also move this wrapping step out to `CYO::from_pathname` where there
        #       is already an explicit allocation of a new wrapper `::Pathname`.
        message = ::CHECKING::YOU::IN::GHOST_REVIVAL::Wild_I∕O.new(message) if
          message.is_a?(::Pathname) and not message.is_a?(SharedMIMEinfo)


        # Otherwise handle the message in two tiers depending on its `::Class`.
        # The first tier of `::Class`es represent housekeeping messages, i.e. those where another `::Ractor`
        # did not block waiting for a response immediately after `#send`ing to us).
        # The second tier represent "needle"s which should immediately trigger a CYO type-matching attempt,
        # first against our in-memory types and then against the enabled `SharedMIMEinfo` packages.
        case message
        when ::CHECKING::YOU::OUT then remember_me.call(message)          # Memoize a new fully-loaded CYO.
        when ::CHECKING::YOU::IN  then mr_mime.send(message, move: true)  # Spool a type to load on the next XML parse.
        when ::CHECKING::YOU::OUT::BatonPass then

          # The end-of-parsing `::Set` subclass will contain all needles which triggered the parse,
          # e.g. `#<BatonPass: {#<Wild_I∕O pathname=#<Pathname:/home/okeeblow/hello.jpg>}>`.
          #
          # If a needle made it here it means there was not an initial cached value, triggering an XML search,
          # so we can explicitly memoize whatever the new result is here (even if it's `nil`).
          message.each { |needle|
            # Memoize the needle's `#hash` `::Integer` instead of the needle `::Object` itself,
            # because we will lose access to the real `::Object` after `::Ractor.send(move: true)`-ing it.
            last_message.store(needle.hash, remember_you.call(needle))
            refrain.push(needle.hash)

            # Evict the oldest cached needle/value iff the cache overflows its size limit.
            last_message.delete(refrain.pop) if refrain.size > max_burning

            # Then fulfill our promise using (but not evicting) the just-cached value to avoid the match logic.
            # TODO: Confirm if `move: true` will cause any problems here when dealing with multiple receivers.
            promise_for_life.delete(needle.hash)&.send(
              last_message.fetch(needle.hash),
              move: ::Ractor.shareable?(last_message.fetch(needle.hash)),
            )
          }

        when SharedMIMEinfo then
          # `::Pathname` subclass representing a `shared-mime-info`-format XML package. Toggle them in both parsers.
          mime_jr.send(message)
          mr_mime.send(message)
        when ::TrueClass, ::FalseClass, ::NilClass then next
        else

          # Begin second-tier type matching for an uncached needle.
          i_member = remember_you.call(message)
          if i_member.nil? then
            # If we have no match, first memoize which `::Ractor` wants an answer, and then get ready to parse.
            promise_for_life.store(message.hash, golden_i)
          else
            # If we have a match from already-loaded types, return that without triggering XML parsing.
            # TODO: Support specifying receiver `::Ractor` here (see comment on `promise_for_life`).
            golden_i.send(i_member)
            next
          end

          case message
          when ::CHECKING::YOU::OUT::StickAround, Wild_I∕O then
            mime_jr.send(message, move: true)
            mime_jr.send(true, move: true)
          when ::String, ::Regexp then
            mr_mime.send(message, move: true)
            mr_mime.send(true, move: true)
          else p "Unhandled `#{message.class}` message: #{message}"
          end

        end  # outer `case message`
      end  # while message = ::Ractor.receive
    }  # ::Ractor.new
  end  # def new_area

  # Generic non-blocking `:send` method for arbitrary messages to an area `::Ractor`.
  # Useful for testing.
  def send(message, area_code: self::DEFAULT_AREA_CODE)
    self.areas[area_code].send(message)
  end

  # Blocking method to return the `CHECKING::YOU::OUT` type for a given file extension
  # (may be a `StickAround` or even just a `::String` or `::Pathname`.
  def from_postfix(stick_around, area_code: self::DEFAULT_AREA_CODE)
    unless @postfix_key&.end_with?(stick_around) then
      @postfix_key = ::CHECKING::YOU::OUT::StickAround.new(stick_around, case_sensitive: false)
      @postfix_key.prepend(-?.) unless @postfix_key.include?(-?.)
      @postfix_key.prepend(-?*) unless @postfix_key.include?(-?*)
      @postfix_key.freeze
    end
    self.areas[area_code].send(@postfix_key, move: true)

    # TODO: Genericize this into a `proc` ASAP because it's gross lol
    #       Also because p much the same logic will apply everywhere we're `::receive_if`-ing,
    #       just with minor variations in needle `::Class` and match verification method.
    #       This also seems to be very slow based on how much it lowered my ips-count. Maybe due to `#any?`?
    ::Ractor.receive_if { |message|
      case message
      when ::CHECKING::YOU::OUT then
        case message.postfixes
        when ::NilClass then false
        when ::CHECKING::YOU::OUT::StickAround then message.postfixes.eql?(@postfix_key)
        when ::Set then message.postfixes.any? { _1.eql?(@postfix_key) }
        else false
        end
      when ::Set then
        message.all? { |msg|
          case msg.postfixes
          when ::NilClass then false
          when ::CHECKING::YOU::OUT::StickAround then msg.postfixes.eql?(@postfix_key)
          when ::Set then msg.postfixes.any? { _1.eql?(@postfix_key) }
          else false
          end
        }
      else false
      end
    }
  end

  # Blocking method to return the `::CHECKING::YOU::OUT` type for a given `::Pathname` based on all possible
  # matching conditions (file extname, complex filename glob, and content match iff the file exists).
  def from_pathname(stick_around, area_code: self::DEFAULT_AREA_CODE)
    # Explicitly construct a new `::Pathname` to allow us to handle `::String` and other input,
    # Normally I would avoid allocating additional objects when given the needed type,
    # but `::Ractor#send` will copy the message object anyway by default (avoided here with `move: true`).
    self.areas[area_code].send(::Pathname.new(stick_around), move: true)
    ::Ractor.receive
  end

end  # CHECKING::YOU::IN::GHOST_REVIVAL


module CHECKING::YOU::OUT::GHOST_REVIVAL
  # Generic blocking `:send` method for arbitrary messages to an area `::Ractor`.
  # Useful for testing.
  def [](only_one_arg, area_code: self.superclass::DEFAULT_AREA_CODE)
    self.areas[area_code].send(only_one_arg)
    ::Ractor.receive
  end
end  # module CHECKING::YOU::OUT::GHOST_REVIVAL
