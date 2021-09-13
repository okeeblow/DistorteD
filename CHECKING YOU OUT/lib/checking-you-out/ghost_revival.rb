require(-'file') unless defined?(::File)
require(-'pathname') unless defined?(::Pathname)
require(-'set') unless defined?(::Set)

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
require_relative(-'ghost_revival/filter_house') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::ONE_OR_EIGHT)


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
module ::CHECKING::YOU::OUT::GHOST_REVIVAL

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


  # Message `::Struct` for inter-`::Ractor` communication. These will be sent with `move: true`
  # and will be mutable. The receiver `::Ractor` will take the `:request`, mutate the message
  # to contain the resulting `:response`, and send the mutated message to the `:destination`.
  #
  # TODO: Re-evaluate this in Ruby 3.1+ depending on the outcome of https://bugs.ruby-lang.org/issues/17298
  EverlastingMessage = ::Struct.new(:destination, :request, :response) do
    # Hash the entire message based on the `#hash` of its `:request` member.
    # The resulting `::Integer` will be used in the cache `::Hash`/`::Set` because the message
    # object itself will become a `::Ractor::MovedObject` after it's sent to `:destination`.
    def hash; self[:request].hash; end
  end


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
      complexes     = set_me_free.new          # `{StickAround => CYO}` container for more complex filename fragments.
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

        # Memoize single-extname "postfixes" separately from more complex filename fragments
        # to allow work and record-keeping with pure extnames.
        postfixes.bury(cyo.postfixes, cyo)
        complexes.bury(cyo.complexes, cyo)

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
        when ::CHECKING::YOU::OUT::StickAround then complexes[needle] || postfixes[needle]
        when ::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O then
          # "If a MIME type is provided explicitly (eg, by a ContentType HTTP header, a MIME email attachment,
          #  an extended attribute or some other means) then that should be used instead of guessing."
          # This will probably always be `nil` since this is a niche feature, but we have to test it first.
          # TODO: Find/write some kind of xattr support that works in `::Ractor`-land.
          xattr = nil#EXTEND_JOY.call(needle).values.map(&ietf_parser.method(:call))
          unless xattr.nil? or xattr&.empty? then xattr.first
          else
            ::CHECKING::YOU::OUT::GHOST_REVIVAL::MAGIC_CHILDREN.call(
              (complexes[needle.stick_around] || postfixes[needle.stick_around]),
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

      # Cache recent results to avoid re-running matching logic.
      # Use a `Hash` to store the last return value for a configurable number of previous query messages.
      # Use `Thread::Queue` to handle cache eviction of oldest keys from the `Hash`.
      last_message = ::Hash.new
      refrain      = ::Thread::Queue.new
      # Cache unmatchable messages to minimize denial-of-service risk if we get sent an unmatchable message in a loop.
      nφ_crime     = ::Set.new


      # Main message loop to process incoming `::Ractor` message queue for instructions.
      # This will block when the queue empties.
      while message = ::Ractor.receive

        case message
        when ::CHECKING::YOU::OUT then remember_me.call(message)          # Memoize a new fully-loaded CYO.
        when ::CHECKING::YOU::IN  then mr_mime.send(message, move: true)  # Spool a type to load on the next XML parse.
        when SharedMIMEinfo then
          # `::Pathname` subclass representing a `shared-mime-info`-format XML package. Toggle them in both parsers.
          mime_jr.send(message)
          mr_mime.send(message)
        when ::TrueClass, ::FalseClass, ::NilClass then next
        when EverlastingMessage then
          # An `EverlastingMessage` is a `::Struct` message we MUST respond to, either with a CYO, a `::Set` of CYOs, or `nil`.
          # We will fill in its `#response` member with the result of running its `#request` through our type-matching logic,
          # then send the mutated message to the `::Ractor` specified in its `#destination` member.
          i_member = last_message[message.hash] || remember_you.call(message.request)
          if nφ_crime.delete?(message.hash) or not i_member.nil? then
            unless last_message.has_key?(message.hash)
              refrain.push(message.hash)
              # Ensure shareability of our response value or we will hit a `::Ractor::MovedObject`
              # the second (cached) time we try to return it since we would have assigned it
              # by reference to the first message which was returned with `move: true`.
              last_message.store(message.hash, ::Ractor.make_shareable(i_member))
              last_message.delete(refrain.pop) if refrain.size > max_burning
            end
            message.response = i_member
            message.destination.send(message, move: true)
          else
            # NOTE: This relies on an implementation detail of MRI where `::Set`s maintain insertion order:
            # irb> lol = Set[:a, :b, :c] => #<Set: {:a, :b, :c}>
            # irb> lol.delete(lol.first) => #<Set: {:b, :c}>
            # irb> lol.delete(lol.first) => #<Set: {:c}>
            # irb> lol.delete(lol.first) => #<Set: {}>
            nφ_crime.delete(nφ_crime.first) if nφ_crime.size > max_burning
            nφ_crime.add(message.hash)

            case message.request
            when ::CHECKING::YOU::OUT::StickAround, Wild_I∕O then
              mime_jr.send(message.request, move: false)
              mime_jr.send(message, move: true)
            when ::String, ::Regexp then
              mr_mime.send(message.request, move: false)
              mr_mime.send(message, move: true)
            else p "Unhandled `#{message.request.class}` EverlastingMessage request: #{message}"
            end  # case message.request
          end  # if i_member

        else p "Unhandled `#{message.class}` message: #{message}"; next
        end  # case message
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
      @postfix_key.freeze
    end
    self.areas[area_code].send(
      EverlastingMessage.new(::Ractor.current, @postfix_key),
      move: true,
    )
    ::Ractor.receive_if {
      |msg| msg.is_a?(EverlastingMessage) and msg.request == @postfix_key
    }.response
  end

  # Blocking method to return the `::CHECKING::YOU::OUT` type for a given `::Pathname` based on all possible
  # matching conditions (file extname, complex filename fragment, and content match iff the file exists).
  def from_pathname(stick_around, area_code: self::DEFAULT_AREA_CODE)
    # HACK: Wrap `::Pathname` needle messages into our own `::Struct` so we can pass around the `::Pathname` itself,
    # its `::IO` stream (from `#open` iff it represents an extant file), and its `::StickAround` as a single unit.
    pathname_key = ::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O.new(stick_around)
    wanted = pathname_key.hash
    self.areas[area_code].send(
      EverlastingMessage.new(::Ractor.current, pathname_key),
      move: true,
    )
    ::Ractor.receive_if {
      |msg| msg.is_a?(EverlastingMessage) and msg.request.hash == wanted
    }.response
  end

  # Generic blocking `:send` method for arbitrary messages to an area `::Ractor`.
  # Useful for testing.
  def [](only_one_arg, area_code: self.superclass::DEFAULT_AREA_CODE)
    wanted = only_one_arg.hash
    self.areas[area_code].send(EverlastingMessage.new(::Ractor.current, only_one_arg), move: true)
    ::Ractor.receive_if {
      |msg| msg.is_a?(EverlastingMessage) and msg.request.hash == wanted
    }.response
  end
end  # module CHECKING::YOU::OUT::GHOST_REVIVAL
