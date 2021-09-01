require(-'set') unless defined?(::Set)
require(-'pathname') unless defined?(::Pathname)

# https://github.com/jarib/ffi-xattr
require(-'ffi-xattr') unless defined?(::Xattr)

# Assorted specialty data structure classes / modules.
require_relative(-'ghost_revival/weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)
require_relative(-'ghost_revival/stick_around') unless defined?(::CHECKING::YOU::OUT::StickAround)

# Components for locating `shared-mime-info` XML packages system-wide and locally to CYO.
require_relative(-'ghost_revival/discover_the_life') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::SharedMIMEinfo)
require_relative(-'ghost_revival/xross_infection') unless defined?(::CHECKING::YOU::OUT::XROSS_INFECTION)

# Actual `shared-mime-info` parsers.
require_relative(-'ghost_revival/mime_jr') unless defined?(::CHECKING::YOU::OUT::MIMEjr)
require_relative(-'ghost_revival/mr_mime') unless defined?(::CHECKING::YOU::OUT::MrMIME)

# Data structures for storing loaded type data in-memory in a usable way.
require_relative(-'ghost_revival/set_me_free') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::SET_ME_FREE)

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

  # Default `::Ractor` CYO data area name.
  # This will be the area used for all synchronous method invocations that do not specify otherwise.
  DEFAULT_AREA_CODE = -'CHECKING YOU OUT'

  # Memoization `::Hash` for all running CYO `::Ractor`s!
  # Keyed on the area name, usually the value in `DEFAULT_AREA_CODE`.
  def areas
    @areas ||= Hash.new { |areas, area_code|
      # Create a new `::Ractor` CYO container and `#send` it every available MIME-info XML package.
      areas[area_code] =
        discover_fdo_xml
          .each_with_object(self.new_area(area_code: area_code)) { |xml_path, area|
            area.send(xml_path)
          }
    }
  end


  # Never return empty Enumerables.
  # Yielding-self to this proc will `nil`-ify anything that's `:empty?`
  # and will pass any non-Enumerable Objects through.
  POINT_ZERO = Ractor.make_shareable(proc { _1.respond_to?(:empty) ? (_1.empty? ? nil : _1) : _1 })

  # Our matching block will return a single CYO when possible, and can optionally
  # return multiple CYO matches for ambiguous files/streams.
  # Multiple matching must be opted into with `only_one_match: false` so it doesn't need to be
  # checked by every caller that's is fine with best-effort and wants to minimize allocations.
  ONE_OR_EIGHT = Ractor.make_shareable(proc { |huh|
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
  EXTEND_JOY = Ractor.make_shareable(proc { |pathname|
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
    ::Ractor.new(Ractor.current, name: area_code) { |outer|

      # These `Hash` sub-classes needs to be defined in the `Ractor` scope afaict because of the additional methods,
      # otherwise trying to `:merge` or `:bury` results in a `defined in a different Ractor (RuntimeError)`.
      #
      # Using the `class SetMeFree < ::Hash; def whatever` syntax instead of `#define_method` didn't change anything.
      # Using a generator method to pass in a `Ractor`-specific `Class` as an argument to `Ractor::new`
      # didn't change anything, since the generator method is still in the outer context when called.
      # It seems the actual code has to be `instance_eval`ed here in the `Ractor` scope v(._. )v
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
      mime_jr       = ::CHECKING::YOU::OUT::MIMEjr::new(Ractor.current, ietf_parser)  # `Pathname`/`IO` => `CYI`
      mr_mime       = ::CHECKING::YOU::OUT::MrMIME::new(Ractor.current, ietf_parser)  # …and `CYI` => `CYO`.


      # Memoize the full-object parser's return `Hash` of `{CYI => CYO}`.
      remember_me = proc { |(cyi, cyo)|
        # Main memoization `Hash` keyed by `CYI`.
        all_night.bury(cyi, cyo)

        # Memoize single-extname "postfixes" separately from more complex filename globs
        # to allow work and record-keeping with pure extnames.
        postfixes.bury(cyo.postfixes, cyo)
        globs.bury(cyo.globs, cyo)

        # Memoize content-match byte sequences in nested `Hash`es based on the starting and ending
        # byte offset where each byte sequence may be found in a hypothetical file/stream.
        case cyo.cat_sequence
        when ::NilClass then next
        when ::Set then
          cyo.cat_sequence&.each { |action|
            as_above.bury(action.min, action.max, action, cyo)
          }
        else
          as_above.bury(cyo.cat_sequence.min, cyo.cat_sequence.max, cyo.cat_sequence, cyo)
        end
      }

      # HACK: Define a re-usable scratch `StickAround` key for filename matching against `StickAround`-keyed `Hash`es.
      # This is a workaround for MRI's behavior where the *given* object's `:eql?` is tested against all `Hash` keys
      # instead of each key's `:eql?` being tested against the given object.
      glob_needle  = ::CHECKING::YOU::OUT::StickAround.new

      # Cache recent results to minimize denial-of-service risk if we get sent an unmatchable message in a loop.
      # Use a `Hash` to store the last return value for a configurable number of previous query messages.
      # Use `Thread::Queue` to handle cache eviction of oldest keys from the `Hash`.
      last_message = ::Hash.new
      refrain      = ::Thread::Queue.new
      max_burning  = 111

      # Process incoming `Ractor` message queue for instructions.
      # This will block when the queue empties.
      #
      # TODO: Make it impossible for this to deadlock. Right now due to use of the blocking methods
      #       `Ractor.yield`/`Ractor.take` any failure of the matching loop will leave the caller blocking!
      #       I will probably end up eliminating use of `::yield` here entirely.
      while message = ::Ractor.receive

        # Return a cached value if we have one.
        answer = nil
        if last_message.has_key?(message) then
          ::Ractor.yield(last_message[message])
          next
        end

        # Otherwise handle the message depending on its class.
        # If `answer` is set (not `nil`) then it will be `yield`ed.
        case message
        when ::CHECKING::YOU::IN then
          answer = all_night[message] || handler.search(message).each_pair(&remember_me)
        #when ::Array, ::Set then  # TODO: Handle batching
        when ::CHECKING::YOU::OUT::StickAround then
          # Perform a filename-only match, on complex globs first and then on single-extnames.
          if globs.has_key?(message) then answer = globs[message]
          elsif postfixes.has_key?(message) then answer = postfixes[message]
          else
            # If there was no match then try loading the data for a new type.
            # If this still returns nothing then we just have no match for this query,
            # and a `nil` result will be memoized in `last_message`.
            loaded = mr_mime.search(mime_jr.search(message)).each_pair(&remember_me)
            answer = loaded.yield_self(&ONE_OR_EIGHT) || globs[glob_needle] || postfixes[glob_needle]
          end
        when ::String then
          if message.count(-?/) == 1 and not message.include?(-?*) then
            # A `String` may be an IETF-style Media-Type.
            cyi = ietf_parser.call(message)
            Ractor.yield(all_night[cyi] || mr_mime.search(cyi).each_pair(&remember_me).yield_self(&ONE_OR_EIGHT))
          else
            # …or it may be a wildcard/glob match against all available IETF Media-Type `String`s in our XML.
            loaded = mr_mime.search(message).each_pair(&remember_me)
            glob_needle.replace(message.to_s)
            answer = loaded.yield_self(&ONE_OR_EIGHT) || globs[glob_needle] || postfixes[glob_needle]
          end
        when ::Regexp then
          # Match the given regular expression against all available IETF Media-Type `String`s in our XML.
          answer = mr_mime.search(message).each_pair(&remember_me).values.yield_self(&POINT_ZERO)
        when SharedMIMEinfo then
          # `::Pathname` subclass representing a `shared-mime-info`-format XML package.
          # Toggle them in both parsers.
          mime_jr.toggle_package(message)
          mr_mime.toggle_package(message)
        when ::Pathname then  # MUST come after subclasses like `SharedMIMEinfo`!
          # Re-use a local scratch `StickAround` as the `Hash` key for filename matching.
          glob_needle.replace(message.to_s)
          # Does the `::Pathname` represent an extant file?
          if message.exist? then
            # "If a MIME type is provided explicitly (eg, by a ContentType HTTP header, a MIME email attachment,
            #  an extended attribute or some other means) then that should be used instead of guessing."
            # This will probably always be `nil` since this is a niche feature, but we have to test it first.
            xattr = nil#EXTEND_JOY.call(message).values.map(&ietf_parser.method(:call))
            unless xattr.nil? or xattr&.empty? then
              answer = xattr.first
            else
              # File exists but has no xattr-defined type. Open the file for magic-matching.
              stream = message.open(mode=File::Constants::RDONLY|File::Constants::BINARY)
              # Run our matching rules on the combination of filename and stream content.
              answer = ::CHECKING::YOU::IN::GHOST_REVIVAL::MAGIC_CHILDREN.call(
                (globs[glob_needle] || postfixes[glob_needle]),
                as_above.so_below(stream),
              )
              # If our rules returned a `nil` match and this `Pathname` wasn't seen recently,
              # try passing it through our XML parser to load an appropriate type.
              if answer.nil? then
                should_load = mime_jr.search([message, stream])
                loaded = mr_mime.search(should_load)
                loaded.each_pair(&remember_me)
                # Run our matching rules on the combination of filename and stream content *again*,
                # but accept that another `nil` match means we should give up :)
                answer = ::CHECKING::YOU::IN::GHOST_REVIVAL::MAGIC_CHILDREN.call(
                  (globs[glob_needle] || postfixes[glob_needle]),
                  as_above.so_below(stream),
                )
              end
            end
          else
            # The `Pathname` describes a file that does not exist. Match filename only.
            answer = (globs[glob_needle] || postfixes[glob_needle])
            if answer.nil? then
              should_load = mime_jr.search([message, stream])
              loaded = mr_mime.search(should_load)
              loaded.each_pair(&remember_me)
              answer = (loaded.yield_self(&ONE_OR_EIGHT) || globs[glob_needle] || postfixes[glob_needle])
            end
          end
        else p "Unhandled #{message}"
        end

        # Any `answer` should be `yield`ed. Memoize the `answer` first for the given `message`,
        # and forget the oldest cached answer if the cache exceeds its maximum size.
        unless answer.nil? then
          last_message.store(message, answer)
          refrain.push(message)
          last_message.delete(refrain.pop) if refrain.size > max_burning
          ::Ractor.yield(answer)
        end

      end  # while message = ::Ractor.receive
    }  # ::Ractor.new
  end  # def new_area

  # Generic blocking `:send` method for arbitrary messages to an area `Ractor`.
  # Useful for testing.
  def send(postfix, area_code: DEFAULT_AREA_CODE)
    self.areas[area_code].send(postfix).take
  end

  # Blocking method to return the `CHECKING::YOU::OUT` type for a given file extension
  # (may be a `StickAround` or even just a `String` or `Pathname`.
  def from_postfix(stick_around, area_code: DEFAULT_AREA_CODE)
    unless @postfix_key&.end_with?(stick_around) then
      @postfix_key = ::CHECKING::YOU::OUT::StickAround.new(stick_around, case_sensitive: false)
      @postfix_key.prepend(-?.) unless @postfix_key.include?(-?.)
      @postfix_key.prepend(-?*) unless @postfix_key.include?(-?*)
      @postfix_key.freeze
    end
    self.areas[area_code].send(@postfix_key, move: true).take
  end

  # Blocking method to return the `Checking::YOU::OUT` type for a given `Pathname` based on all possible
  # matching conditions (file extname, complex filename glob, and content match iff the file exists).
  def from_pathname(stick_around, area_code: DEFAULT_AREA_CODE)
    # Explicitly construct a new `Pathname` to allow us to handle `String` and other input,
    # Normally I would avoid allocating additional objects when given the needed type,
    # but `Ractor.send` will copy the message object anyway by default (avoided here with `move: true`).
    self.areas[area_code].send(Pathname.new(stick_around), move: true).take
  end

end  # CHECKING::YOU::IN::GHOST_REVIVAL


module CHECKING::YOU::OUT::GHOST_REVIVAL
  DEFAULT_AREA_CODE = -'CHECKING YOU OUT'
  def [](only_one_arg, area_code: DEFAULT_AREA_CODE)
    self.areas[area_code].send(only_one_arg).take
  end
end  # module CHECKING::YOU::OUT::GHOST_REVIVAL
