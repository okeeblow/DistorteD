require(-'file') unless defined?(::File)
require(-'pathname') unless defined?(::Pathname)
require(-'set') unless defined?(::Set)

# Assorted specialty data structure classes / modules for storing loaded type data in-memory in a usable way.
require_relative(-'ghost_revival/set_me_free') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::SET_ME_FREE)
require_relative(-'ghost_revival/stick_around') unless defined?(::CHECKING::YOU::OUT::StickAround)
require_relative(-'ghost_revival/ultravisitor') unless defined?(::CHECKING::YOU::OUT::ULTRAVISITOR)
require_relative(-'ghost_revival/weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)
require_relative(-'ghost_revival/wild_io') unless defined?(::CHECKING::YOU::OUT::Wild_I∕O)

# Components for locating `shared-mime-info` XML packages system-wide and locally to CYO.
require_relative(-'ghost_revival/discover_the_life') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::SharedMIMEinfo)
require_relative(-'ghost_revival/xross_infection') unless defined?(::CHECKING::YOU::OUT::XROSS_INFECTION)

# Actual `shared-mime-info` parsers.
require_relative(-'ghost_revival/mime_jr') unless defined?(::CHECKING::YOU::OUT::MIMEjr)
require_relative(-'ghost_revival/mr_mime') unless defined?(::CHECKING::YOU::OUT::MrMIME)

# Decision-making matrix for various combinations of filename- and content-matches.
require_relative(-'ghost_revival/filter_house') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::ONE_OR_EIGHT)
require_relative(-'ghost_revival/magic_has_the_right_to_children') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::MAGIC_CHILDREN)
require_relative(-'ghost_revival/round_and_round') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND)


# This module contains the core data-loading components for turning source data into usable in-memory structures.
# TL;DR: Anything having to do with CYO `::Ractor` communication goes in here.
module ::CHECKING::YOU::OUT::GHOST_REVIVAL

  # We will remember our computed answer to a configurable number of recently-seen needles
  # (e.g. `::Pathname`s or `:IO` streams) for performance, especially with unmatchable needles.
  DEFAULT_CACHE_SIZE = 111.freeze

  APPLICATION_OCTET_STREAM = ::CHECKING::YOU::IN::new(:possum, :application, :"octet-stream").freeze
  APPLICATION_XML = ::CHECKING::YOU::IN::new(:possum, :application, :xml).freeze
  TEXT_PLAIN = ::CHECKING::YOU::IN::new(:possum, :text, :plain).freeze
  STILL_IN_MY_HEART = ::Array[
    APPLICATION_OCTET_STREAM,
    APPLICATION_XML,
    TEXT_PLAIN,
  ].freeze


  # Find a running CYO `::Ractor`, creating it if necessary.
  # Keyed on the area name `::Symbol`, usually the value in `DEFAULT_AREA_CODE`.
  AREAS = ::Ractor::make_shareable(proc { |area_code|
    # Disabling the `inherit` argument to all const methods so we can't accidentally
    # wander up the namespace out of `GHOST_REVIVAL`.
    if(self.const_defined?(area_code.to_sym, inherit=false)) then
      self.const_get(area_code.to_sym, inherit=false)
    else
      # Create a new `::Ractor` CYO container and `#send` it every available MIME-info XML package.
      self.const_set(
        area_code.to_sym,

        ::Ractor::new(
          ::Ractor::make_shareable(proc {
            DISCOVER_FDO_XML.call
              .each_with_object(NEW_AREA.call(area_code: area_code)) { |xml_path, area|
                area.send(xml_path)
              }
          }),
          area_code,
          name: -"ULTRAVISITOR::#{area_code.to_s}",
          &::CHECKING::YOU::OUT::ULTRAVISITOR
        )

      )  # const_set
    end
  })


  # Construct a `Ractor` container for a single area of type data, chosen by the `area_code` parameter.
  # This allows separate areas for separate services/workflows running within the same Ruby interpreter.
  NEW_AREA = ::Ractor::make_shareable(->(
    area_code:   DEFAULT_AREA_CODE,   # Unique name for each separate a pool of CYO types.
    max_burning: DEFAULT_CACHE_SIZE,  # Number of type definitions to keep in memory. No limit iff `0`.
    how_long:    DEFAULT_CACHE_SIZE   # Number of queries and their type-match-responses to keep in memory.
  ) {
    # `::Ractor.new` won't take arbitrary named arguments, just positional.
    ::Ractor.new(area_code, max_burning, how_long, name: area_code.to_s) { |area_code, max_burning, how_long|

      # These `::Hash` sub-classes needs to be defined in the `::Ractor` scope because the block argument to `:define_method`
      # is un-shareable, otherwise trying to `:merge` or `:bury` results in a `defined in a different Ractor (RuntimeError)`:
      # - https://bugs.ruby-lang.org/issues/17722 
      # - https://github.com/ruby/ruby/pull/4771/commits/b92c26a56fb515c9225cfd11e965abffe583e0a5
      set_me_free         = self.instance_eval(&SET_ME_FREE)
      magic_without_tears = self.instance_eval(&::CHECKING::YOU::OUT::SweetSweet♡Magic::MAGIC_WITHOUT_TEARS)

      # Instances of the above classes to hold our type data.
      all_night     = set_me_free.new          # Main `{CYI => CYO}` container.
      line_4_ruin   = ::Thread::Queue.new      # Eviction order for oldest `CYO` when loaded-type count exceeds `max_burning`.
      postfixes     = set_me_free.new          # `{StickAround => CYO}` container for Postfixes (extnames).
      complexes     = set_me_free.new          # `{StickAround => CYO}` container for more complex filename fragments.
      as_above      = magic_without_tears.new  # `{offsets => (Speedy|Sequence)Cat` => CYO}` container for content matching.

      # Two-step `shared-mime-info` XML parsers.
      # `Ractor`-ized CYO supports partial loading of type data à la `mini_mime` to conserve memory and minimize allocations
      # (formerly ~18k retained objects to load all available types from all available packages vs. ~3k retained for a basic set now).
      #
      # Partial-loading isn't as simple as parsing the discovered XML packages against a given `Pathname`/`IO` on the fly
      # and returning any matching CYO objects as they are parsed, because a single type's definition can be spread out
      # over any number of XML package files. We may have passed by and discarded parts of a type's definition by the time
      # we get to the XML package having a positive filename or content match for that type.
      # Additionally, the `shared-mime-info` specification allows XML packages to alter or purge certain parts of a type's
      # definition loaded from a previously-parsed package, e.g. the `<glob-deleteall>` and the `<magic-deleteall>` elements,
      # so CYO can't load only the fragment of a matched type's definition that comes from the package containing the match.
      #
      # To support this I split the XML parser into two parts:
      # - `MrMIME` is the traditional parser which builds fully-defined `::CHECKING::YOU::OUT` type objects from the source XML,
      #   but now instead of just loading all available types it takes `CHECKING::YOU::IN` (or a `String` or `Regexp`!) "needles"
      #   and loads only the types matching those needles — e.g. a `::String` `"*jpeg"` will match `image/jpeg` and `video/x-mjpeg`.
      # - `MIMEjr` is the newer parser which takes a `Pathname` or `IO`-like stream (e.g. from `File.open`) and performs on-the-fly
      #   filename and content matching — generating `CHECKING::YOU::IN` key `Struct`s representing the matched types.
      #   It sends those `CYI`s to `MrMIME` as the needles for its next parse and then triggers `MrMIME` to parse.
      #
      # This is faster than the traditional load of all available types despite doing two parse passes of all XML packages,
      # because both parsers intentionally throw away as much data as possible and incur vastly fewer allocations!
      #
      # These two parsers and our memoization collections are our equivalent of the reference implementation's `update-mime-database`:
      # https://cgit.freedesktop.org/xdg/shared-mime-info/tree/src/update-mime-database.c
      mr_mime       = ::CHECKING::YOU::OUT::MrMIME::new                     # `CYI`/`String`/`Regexp` => `CYO`.
      mime_jr       = ::CHECKING::YOU::OUT::MIMEjr::new(receiver: mr_mime)  # `Pathname`/`IO`         => `CYI`.

      # Evict a single `::CHECKING::YOU::IN`'s related data from all memoization structures.
      kick_out_仮面 = proc { |cyi|
        all_night.delete(cyi).tap { |cyo|
          postfixes.baleet(cyo.postfixes, cyo)
          complexes.baleet(cyo.complexes, cyo)
          case cyo.cat_sequence
          when ::NilClass then next
          when ::Set then cyo.cat_sequence&.each { |action| as_above.baleet(action.min, action.max, action, cyo) }
          else as_above.baleet(cyo.cat_sequence.min, cyo.cat_sequence.max, cyo.cat_sequence, cyo)
          end
        }
      }

      # Memoize a single new `::CHECKING::YOU::OUT` type instance.
      remember_me   = proc { |cyi, cyo|
        # Main memoization `::Hash` and cache-eviction-order `::Queue`keyed by `CYI`.
        all_night.bury(cyi, cyo)
        # Some types should be kept in-memory forever no matter their age.
        line_4_ruin.push(cyi) unless STILL_IN_MY_HEART.include?(cyi)

        # Memoize single-extname "postfixes" separately from more complex filename fragments
        # to allow work and record-keeping with pure extnames.
        postfixes.bury(cyo.postfixes, cyo)
        complexes.bury(cyo.complexes, cyo)

        # Memoize content-match byte sequences in nested `Hash`es based on the starting and ending
        # byte offset where each byte sequence may be found in a hypothetical file/stream.
        case cyo.cat_sequence
        when ::NilClass then next
        when ::Set then cyo.cat_sequence&.each { |action| as_above.bury(action.min, action.max, action, cyo) }
        else as_above.bury(cyo.cat_sequence.min, cyo.cat_sequence.max, cyo.cat_sequence, cyo)
        end

        # Evict the oldest-loaded type once we hit our cache limit.
        # A limit of `0` disables eviction, allowing one to load all available types simultaneously.
        kick_out_仮面.call(line_4_ruin.pop) if line_4_ruin.size > max_burning and max_burning > 0
      }

      # Convert a CYO (or collection of CYOs) into new duplicate `Object`s having their `:parent` CYIs
      # resolved to the matching CYO type from this same working set.
      together_4ever = proc { |cyo, include_implicit=false|
        case cyo
        when ::CHECKING::YOU::OUT then
          case cyo.parents
          in ::NilClass then cyo
          in ::CHECKING::YOU::OUT => parent then parent
          in ::CHECKING::YOU::IN => parent then
            ((parent == APPLICATION_OCTET_STREAM or parent == TEXT_PLAIN) and not include_implicit) ? cyo :
              cyo.dup.tap {
                _1.instance_variable_set(:@parents, together_4ever.call(all_night[parent]))
              }
          in ::CHECKING::YOU::IN::B4U => parent then cyo.dup.tap {
            _1.instance_variable_set(:@parents, together_4ever.call(all_night[parent]))
          }
          in ::Set => parents then
            cyo.dup.tap {
              _1.instance_variable_set(:@parents, parents.map(&all_night.method(:[])).map!(&together_4ever).compact.to_set)
            }
          else cyo
          end
        when ::Set, ::Array then cyo.map!(&together_4ever)
        when ::NilClass then nil
        else nil
        end
      }

      # Return the best guess for a given needle's type based on our currently-loaded data.
      # A return value of `nil` here will trigger a `SharedMIMEinfo` XML package search
      # the first time that needle is seen (or if it has been purged from our cache).
      remember_you  = proc { |needle|
        case needle
        when ::CHECKING::YOU::IN, ::CHECKING::YOU::IN::B4U then all_night[needle].yield_self(&together_4ever)
        when ::CHECKING::YOU::OUT::StickAround then (complexes[needle] || postfixes[needle]).yield_self(&together_4ever)
        when ::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O then
          # "If a MIME type is provided explicitly (eg, by a ContentType HTTP header, a MIME email attachment,
          #  an extended attribute or some other means) then that should be used instead of guessing."
          # This will probably always be an empty `::Array` since this is a niche feature, but we have to test it first.
          steel_needles = ::CHECKING::YOU::OUT::StellaSinistra::STEEL_NEEDLE.call(needle).map!(&all_night::method(:[]))
          unless steel_needles.nil? or steel_needles&.empty? then steel_needles.first.yield_self(&together_4ever)
          else
            ::CHECKING::YOU::OUT::GHOST_REVIVAL::MAGIC_CHILDREN.call(
              (complexes[needle.stick_around] || postfixes[needle.stick_around]).yield_self(&together_4ever),
              as_above.so_below(needle.stream).transform_values!(&together_4ever),
            )
          end
        when ::String then all_night[::CHECKING::YOU::IN::from_ietf_media_type(needle)].yield_self(&together_4ever)
        end  # case needle
      }

      # Cache recent results to avoid re-running matching logic.
      # Use a `Hash` to store the last return value for a configurable number of previous query messages.
      # Use `Thread::Queue` to handle cache eviction of oldest keys from the `Hash`.
      last_message  = ::Hash.new
      refrain       = ::Thread::Queue.new
      # Cache unmatchable messages to minimize denial-of-service risk if we get sent an unmatchable message in a loop.
      nφ_crime      = ::Set.new


      # Main message loop to process incoming `::Ractor` message queue for instructions.
      # This will block when the queue empties.
      # NOTE: `while case ::Ractor::receive` is syntactically valid, but it seems to stop executing
      #       part way through the `case` statement unless I assign it to a variable first and `case` that.
      while _message = ::Ractor::receive
        case _message
        in ::CHECKING::YOU::OUT     => cyo then remember_me.call(cyo.in, cyo)  # Memoize a new fully-loaded CYO.
        in ::CHECKING::YOU::IN      => cyi then mr_mime.send(cyi, move: true)  # Spool a type to load on the next XML parse.
        in ::Fixnum                 => max then max_burning = max              # Control CYO cache length (for loaded types).
        in ::CHECKING::YOU::IN      => cyi, ::CHECKING::YOU::OUT => cyo then remember_me.call(cyi, cyo)
        in ::CHECKING::YOU::IN::B4U => cyi, ::CHECKING::YOU::OUT => cyo then remember_me.call(cyi, cyo)
        in SharedMIMEinfo           => mime_package
          # `::Pathname` subclass representing a `shared-mime-info`-format XML package. Toggle them in both parsers.
          mime_jr.send(mime_package)
          mr_mime.send(mime_package)
        in ::CHECKING::YOU::IN::EverlastingMessage => message then
          # An `EverlastingMessage` is a `::Struct` message we MUST respond to, either with a CYO, a `::Set` of CYOs, or `nil`.
          # We will fill in its `#response` member with the result of running its `#request` through our type-matching logic,
          # then send the mutated message to the `::Ractor` specified in its `#destination` member.
          i_member = last_message[message.in_motion.hash] || remember_you.call(message.in_motion)
          if nφ_crime.delete?(message.in_motion.hash) or not i_member.nil? then
            unless last_message.has_key?(message.in_motion.hash)
              refrain.push(message.in_motion.hash)
              # Ensure shareability of our response value or we will hit a `::Ractor::MovedObject`
              # the second (cached) time we try to return it since we would have assigned it
              # by reference to the first message which was returned with `move: true`.
              last_message.store(message.in_motion.hash, ::Ractor.make_shareable(i_member))
              last_message.delete(refrain.pop) if refrain.size > how_long
            end
            # Mutate the envelope and `::Ractor#send` it on to its embedded destination.
            message.in_motion = i_member
            message.go_beyond!
          else
            # NOTE: This relies on an implementation detail of MRI where `::Set`s maintain insertion order:
            # irb> lol = Set[:a, :b, :c] => #<Set: {:a, :b, :c}>
            # irb> lol.delete(lol.first) => #<Set: {:b, :c}>
            # irb> lol.delete(lol.first) => #<Set: {:c}>
            # irb> lol.delete(lol.first) => #<Set: {}>
            nφ_crime.delete(nφ_crime.first) if nφ_crime.size > how_long
            nφ_crime.add(message.in_motion.hash)

            case message.in_motion
            when ::CHECKING::YOU::OUT::StickAround, Wild_I∕O then
              mime_jr.send(message.in_motion, move: false)
              mime_jr.send(message, move: true)
            when ::String then
              cyi = ::CHECKING::YOU::IN::from_ietf_media_type(message.in_motion)
              case cyi
              when ::CHECKING::YOU::IN then mr_mime.send(cyi, move: true)
              when ::CHECKING::YOU::IN::B4U then
                cyi.each { mr_mime.send(_1, move: false) }
                mr_mime.send(cyi, move: true)
              end
              mr_mime.send(message, move: true)
            when ::Regexp, ::CHECKING::YOU::IN, ::CHECKING::YOU::IN::B4U then
              mr_mime.send(message.in_motion, move: false)
              mr_mime.send(message, move: true)
            else p "Unhandled `#{message.in_motion.class}` EverlastingMessage request: #{message}"
            end  # case message.request
            next
          end  # if nφ_crime.delete?(message.in_motion.hash) or not i_member.nil?

        else p "Unhandled `#{message.class}` message: #{message}"; next
        end  # case ::Ractor::receive
      end  # while
    }  # ::Ractor.new
  })  # NEW_AREA

  include(::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND)

end  # module CHECKING::YOU::OUT::GHOST_REVIVAL
