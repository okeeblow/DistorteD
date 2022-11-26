require(-'file') unless defined?(::File)
require(-'pathname') unless defined?(::Pathname)
require(-'set') unless defined?(::Set)

# Used for URI-scheme parsing instead of the Ruby stdlib `URI` module.
require(-'addressable') unless defined?(::Addressable)

# Assorted specialty data structure classes / modules for storing loaded type data in-memory in a usable way.
require_relative(-'ghost_revival/set_me_free') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::SET_ME_FREE)
require_relative(-'ghost_revival/ultravisitor') unless defined?(::CHECKING::YOU::OUT::ULTRAVISITOR)
require_relative(-'ghost_revival/weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)
require_relative(-'ghost_revival/wild_io') unless defined?(::CHECKING::YOU::OUT::Wild_I∕O)

# Components for locating and parsing `shared-mime-info` XML packages.
require_relative(-'ghost_revival/discover_the_life') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE)
require_relative(-'ghost_revival/mime_jr') unless defined?(::CHECKING::YOU::OUT::MIMEjr)
require_relative(-'ghost_revival/mr_mime') unless defined?(::CHECKING::YOU::OUT::MrMIME)

# Decision-making matrix for various combinations of filename- and content-matches.
require_relative(-'ghost_revival/filter_house') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::ONE_OR_EIGHT)
require_relative(-'ghost_revival/magic_has_the_right_to_children') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::MAGIC_CHILDREN)
require_relative(-'ghost_revival/round_and_round') unless defined?(::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND)


# This module contains the core data-loading components for turning source data into usable in-memory structures.
# TL;DR: Anything having to do with CYO `::Ractor` communication goes in here.
module ::CHECKING::YOU::OUT::GHOST_REVIVAL

  # Class-methods for discovering and loading `SharedMIMEinfo` packages.
  extend(::CHECKING::YOU::OUT::GHOST_REVIVAL::DISCOVER_THE_LIFE)

  # We will memoize a configurable number of CYO type objects. When we reach that limit, the oldest type will be purged.
  # The default cache size used to be `111`, but I bumped it up because it was easy to load more types
  # than that at once with popular categories like images, e.g. `irb> CYO[/image/].size => 122`.
  DEFAULT_TYPE_CACHE_SIZE = 333.freeze

  # We will memoize our computed answer (even if it's `nil`) to a configurable number of recently-seen needles,
  # letting us skip the entire matching sequence, skip the allocation hit from `CYI` to `CYO` enrichment (`together_4ever`),
  # and lets us avoid `MrMIME` round-trips from needles which explicitly always trigger that parser (i.e. `Regexp`)
  # and from invalid needles which eventually produce two `nil` responses in a row.
  DEFAULT_QUERY_CACHE_SIZE = 111.freeze

  # These two types are the implicit parents for any streamable type and any text type, respectively.
  # See https://specifications.freedesktop.org/shared-mime-info-spec/shared-mime-info-spec-latest.html#subclassing
  APPLICATION_OCTET_STREAM = ::CHECKING::YOU::IN::new(:possum, :application, :"octet-stream").freeze
  TEXT_PLAIN = ::CHECKING::YOU::IN::new(:possum, :text, :plain).freeze

  # These types are just very common as parents for other types,
  # so I'm always going to load them in the interest of minimizing XML parser restarts for their children.
  #
  # [okeeblow@emi#shared-mime-info] grep sub-class-of freedesktop.org.xml.in | sed 's/^\s*//g' | sort | uniq -c | sort -nr | head -n 7
  #     153 <sub-class-of type="text/plain"/>
  #      54 <sub-class-of type="application/zip"/>
  #      43 <sub-class-of type="application/xml"/>
  #      19 <sub-class-of type="image/x-dcraw"/>
  #      12 <sub-class-of type="image/tiff"/>
  #      11 <sub-class-of type="text/x-csrc"/>
  #       8 <sub-class-of type="application/gzip"/>
  APPLICATION_XML = ::CHECKING::YOU::IN::new(:possum, :application, :xml).freeze
  APPLICATION_ZIP = ::CHECKING::YOU::IN::new(:possum, :application, :zip).freeze

  # These types will be force-loaded in any CYO area and will never be purged when we overrun the cache limit.
  STILL_IN_MY_HEART = ::Array[
    APPLICATION_OCTET_STREAM,
    APPLICATION_XML,
    APPLICATION_ZIP,
    TEXT_PLAIN,
  ].freeze

  # These needles represent ways a user might load all types at once.
  # If that happens, trust that they know what they want and disable the type cache limit,
  # otherwise it's silly to load 1400+ types but then immediately throw away over a thousand of them.
  INFINITE_PRAYER = ::Set[
    /.*/,
    -'*'
  ].map!(&:freeze).freeze


  # Find a running CYO `::Ractor`, creating it if necessary.
  # Keyed on the area name `::Symbol`, usually the value in `DEFAULT_AREA_CODE`.
  AREAS = ::Ractor::make_shareable(proc { |area_code|
    # Disabling the `inherit` argument to all const methods so we can't accidentally wander up the namespace.
    if(self.const_defined?(area_code.to_sym, inherit=false)) then
      self.const_get(area_code.to_sym, inherit=false)
    else
      # HACK: Only the main `Ractor` can access class-instance variables.
      #       I memoize running CYO areas to constants instead to allow use by non-main `Ractor`s,
      #       including the case where a running CYO area wants to access itself (e.g. `CYI#out`)!
      self.const_set(
        area_code.to_sym,
        # Create a new `::Ractor` CYO container and `#send` it every available MIME-info XML package and permanent type.
        ::Ractor::new(
          ::Ractor::make_shareable(proc {
            STILL_IN_MY_HEART.each_with_object(
              self.shared_mime_info_packages.each_with_object(
                NEW_AREA.call(area_code:)
              ) { |xml_path, area| area.send(xml_path) }
            ) { |permanent_type, area| area.send(permanent_type) }
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
    area_code:   DEFAULT_AREA_CODE,         # Unique name for each separate a pool of CYO types.
    max_burning: DEFAULT_TYPE_CACHE_SIZE,   # Number of type definitions to keep in memory. No limit iff `0`.
    how_long:    DEFAULT_QUERY_CACHE_SIZE  # Number of queries and their type-match-responses to keep in memory.
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
      all_night     = set_me_free.new          # Main `{CYI => CYO}` container for canonical CYI as well as aliases.
      line_4_ruin   = ::Thread::Queue.new      # Eviction order for oldest `CYO` when loaded-type count exceeds `max_burning`.
      sinistar      = set_me_free.new          # `{StellaSinistra/DeusDextera => CYO}` container for Postfixes (extnames).
      astraia       = set_me_free.new          # `{ASTRAIAの双皿 => CYO}` container for more complex filename fragments.
      as_above      = magic_without_tears.new  # `{offsets => (Speedy|Sequence)Cat` => CYO}` container for content matching.
      four_leaf     = set_me_free.new          # `{FourLead => CYO}` FourCC container.
      mother_tree   = set_me_free.new          # `{<treemagic> => CYO}` container.
      re_roots      = set_me_free.new          # `{<root-XML> => CYO}` container.
      regulus       = nil                      # `::Regexp::union` of `CYO#astraia`s — boolean gate for expensive glob comparison.

      # Cache recent results to avoid re-running matching logic.
      # Use a `Hash` to store the last return value for a configurable number of previous query messages.
      # Use `Thread::Queue` to handle cache eviction of oldest keys from the `Hash`.
      last_message  = ::Hash.new
      refrain       = ::Thread::Queue.new
      # Cache unmatchable messages to minimize denial-of-service risk if we get sent an unmatchable message in a loop.
      nφ_crime      = ::Set.new

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
        all_night.delete(cyi)&.tap { |cyo|
          all_night.baleet(cyo.aka, cyo) unless all_night.include?(cyo.aka)  # TODO: Handle conflicting aliasing.
          sinistar.baleet(cyo.sinistar, cyo)
          astraia.baleet(cyo.astraia, cyo)
          mother_tree.baleet(cyo.mother_tree, cyo)
          four_leaf.baleet(cyo.four_leaf, cyo)
          re_roots.baleet(cyo.re_roots, cyo)

          # There isn't a "subtraction" method like the opposite of `::Regexp::union`,
          # so when we want to remove one we have to recompute the whole thing.
          regulus = astraia.keys.empty? ? nil : ::Regexp::union(astraia.keys)

          case cyo.cat_sequence
          when ::NilClass then next
          when ::Set then cyo.cat_sequence&.each { |action| as_above.baleet(action.min, action.max, action, cyo) }
          else as_above.baleet(cyo.cat_sequence.min, cyo.cat_sequence.max, cyo.cat_sequence, cyo)
          end
        }
      }  # kick_out_仮面

      # Memoize a single new `::CHECKING::YOU::OUT` type instance.
      remember_me   = proc { |cyi, cyo|
        # Main memoization `::Hash` and cache-eviction-order `::Queue`keyed by `CYI`.
        all_night.store(cyi, cyo)
        # Some types should be kept in-memory forever no matter their age.
        line_4_ruin.push(cyi) unless STILL_IN_MY_HEART.include?(cyi)
        # Some types may have multiple alias CYIs, like `audio/x-mp3` => `audio/mpeg`.
        all_night.bury(cyo.aka, cyo) unless all_night.include?(cyo.aka)
        # TODO: Handle conflicting aliasing like how freedesktop-dot-org XML has `<mime-type type="application/x-kword">`
        #       but tika-mimetypes has `<mime-type type="application/vnd.kde.kword"><alias type="application/x-kword"/>`.
        #       Right now these get loaded as two separate types:
        #         irb> CHECKING::YOU::OUT::from_iana_media_type("application/x-kword").map(&:to_s)
        #              => ["application/x-kword", "application/vnd.kde.kword"]

        # Memoize single-extnames separately from more complex filename fragments
        # to allow work and record-keeping with pure extnames.
        sinistar.bury(cyo.sinistar, cyo)
        astraia.bury(cyo.astraia, cyo)
        # Use our Glob `#to_regexp` functionality to build a quick bypass of a possibly-expensive `#fnmatch` loop.
        regulus = regulus.nil? ? ::Regexp::union(cyo.astraia) : ::Regexp::union(regulus, *(cyo.astraia)) unless cyo.astraia.nil?

        # Memoize content-match byte sequences in nested `Hash`es based on the starting and ending
        # byte offset where each byte sequence may be found in a hypothetical file/stream.
        case cyo.cat_sequence
        when ::NilClass then nil  # No-op.
        when ::Set then cyo.cat_sequence&.each { |action| as_above.bury(action.min, action.max, action, cyo) }
        else as_above.bury(cyo.cat_sequence.min, cyo.cat_sequence.max, cyo.cat_sequence, cyo)
        end
        four_leaf.bury(cyo.four_leaf, cyo)
        mother_tree.bury(cyo.mother_tree, cyo)
        re_roots.bury(cyo.re_roots, cyo) unless cyo.eql?(APPLICATION_XML)

        # Evict the oldest-loaded type once we hit our cache limit.
        # A limit of `0` disables eviction, allowing one to load all available types simultaneously.
        kick_out_仮面.call(line_4_ruin.pop) if line_4_ruin.size > max_burning and max_burning > 0
      }  # remember_me

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
        when ::Set, ::Array then cyo.dup.map!(&together_4ever)
        when ::NilClass then nil
        else nil
        end
      }  # together_4ever

      # Return the best guess for a given needle's type based on our currently-loaded data.
      # A return value of `nil` here will trigger a `SharedMIMEinfo` XML package search
      # the first time that needle is seen (or if it has been purged from our cache).
      remember_you  = proc { |needle|
        case needle
        when ::CHECKING::YOU::IN, ::CHECKING::YOU::IN::B4U then all_night[needle].yield_self(&together_4ever).yield_self {
          # TODO: Remove this if I can detect and combine FDO and Tika aliases of the same types.
          # Avoids errors from e.g.
          #   tmb_auslandsgesprach.rb:70:in `block (2 levels) in <main>'
          #   <"application/x-java"> expected but was
          #   <"#<Set: {#<CHECKING::YOU::OUT application/x-java>, #<CHECKING::YOU::OUT application/java-vm>}>">
          _1.is_a?(::Set) ? _1.first : _1
        }
        when ::CHECKING::YOU::OUT::StellaSinistra, ::CHECKING::YOU::OUT::ASTRAIAの双皿 then
          (astraia[needle] || sinistar[needle]).yield_self(&together_4ever)
        when ::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O then
          # "If a MIME type is provided explicitly (eg, by a ContentType HTTP header, a MIME email attachment,
          #  an extended attribute or some other means) then that should be used instead of guessing."
          # This will probably always be an empty `::Array` since this is a niche feature, but we have to test it first.
          steel_needles = ::CHECKING::YOU::OUT::VinculumStellarum::STEEL_NEEDLE.call(needle)&.map!(&all_night::method(:[]))
          unless (steel_needles.nil? or steel_needles&.empty?) then steel_needles.first.yield_self(&together_4ever)
          else
            # Get any non-regular (`inode`) or directory (`x-content`) type for a `Pathname`,
            # and if one exists, use it as a parent type for any regular match.
            irregular_nation = ::CHECKING::YOU::OUT::VinculumStellarum::IRREGULAR_NATION.call(needle.pathname)
            casiotone_nation = case
            when needle.directory? then mother_tree.=~(needle.pathname).yield_self(&ONE_OR_EIGHT)
            when (needle.file? and needle.extname.eql?(-'.xml')) then
              # Any XML file with a non-`.xml` file extension is likely to be matchable via its own unique extension,
              # but for `.xml` files we should run our mini-parser to extract the namespace and root-Element name and match that.
              xml_root = ::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots::from_pathname(needle.pathname)
              # `nφ_crime` key is added the first time our loop gets a `nil` from this `Proc`,
              # so return that `nil` here iff we failed to match our `.xml` file's namespace and root Element name.
              # This avoids returning a plain `APPLICATION_XML` match when there is more specific type data not yet loaded.
              nφ_crime.include?(needle.hash) ? re_roots[xml_root] : nil.tap { mime_jr.send(xml_root, move: true) }  
            else
              ::CHECKING::YOU::OUT::GHOST_REVIVAL::MAGIC_CHILDREN.call(
                (
                  regulus&.match?(needle.pathname.to_s) ? needle.pathname.to_s.yield_self { |path|
                    # Avoid allocating with `::Pathname#to_s` every loop.
                    astraia.detect { |glob, cyo| glob.eql?(path) }[1]
                  } : sinistar[needle.sinistar]
                ).yield_self(&together_4ever),
                as_above.so_below(needle.stream)&.transform_values!(&together_4ever),
              )
            end  # casiotone_nation = case
            # If we made an irregular match, add it as a parent type to a regular match (if there was one).
            # If there was an irregular match but no regular match and this is our first time testing this needle,
            # return `nil` to run it through our XML parsers in search of a more-specific type not yet loaded.
            # This avoids partial and inconsistent matches for e.g. removable media having a `<treemagic>` match when mounted,
            # like a camera SD card whose irregular match will be `inode/mountpoint` but whose regular match would be `x-content/image-dcf`.
            irregular_nation.nil? ? casiotone_nation : case casiotone_nation
              when ::NilClass, APPLICATION_OCTET_STREAM then nφ_crime.include?(needle.hash) ? irregular_nation : nil
              else (casiotone_nation.frozen? ? casiotone_nation.dup : casiotone_nation).add_parent(irregular_nation)
            end  # case casiotone_nation
          end
        when ::CHECKING::YOU::OUT::AtomicAge::FourLeaf then four_leaf[needle].yield_self(&together_4ever)
        when ::Addressable::URI then
          # `#downcase` any matched URI scheme since `::Addressable::URI#scheme` won't,
          # but `#scheme#downcase!` will mutate an unfrozen `::Addressable::URI` instance:
          #   irb> (cool =::Addressable::URI::parse("HTTPS://WWW.COOLTRAINER.ORG").scheme => "HTTPS"
          #   irb> cool.scheme.downcase! => "https"
          #   irb> cool.scheme => "https"
          #
          # Per https://datatracker.ietf.org/doc/html/rfc3986#section-3.1  —
          #   "Although schemes are case-insensitive, the canonical form is lowercase
          #   and documents that specify schemes must do so with lowercase letters.
          #   An implementation should accept uppercase letters as equivalent to lowercase
          #   in scheme names (e.g., allow "HTTP" as well as "http") for the sake of robustness
          #   but should only produce lowercase scheme names for consistency."
          #
          # T0D0: If I wanted to fetch and match remote files (I don't) here's where I would do it.
          uri_type = ::CHECKING::YOU::OUT::new(:possum, :"x-scheme-handler", needle.scheme.downcase.to_sym)
          if needle.scheme.downcase.eql?(-'file') then
            # For `file://` URI schemes, additionally get the type of the file at the URI's path,
            # and append `x-scheme-handler/file` as the parent to any match:
            #   irb> ::Addressable::URI::parse("file:///home/okeeblow/あああ.txt").path => "/home/okeeblow/あああ.txt"
            #   irb> CYO::from_uri("file:///home/okeeblow/hello.jpg").to_s => "image/jpeg"
            #   irb> CYO::from_uri("file:///home/okeeblow/hello.jpg").parents.to_s => "x-scheme-handler/file"
            uri_pathname = ::CHECKING::YOU::OUT::GHOST_REVIVAL::Wild_I∕O::new(needle.path)
            uri_pathname.exist? ?
              remember_you.call(uri_pathname).yield_self {
                # Did we match anything for the `::Pathname` represented by this URI?
                # If not, try to identify the contents of this path. If yes, use it but also add a `file://` type parent.
                _1.nil? ?
                  nil.tap { mime_jr.send(uri_pathname, move: true) unless nφ_crime.include?(needle.hash) } :
                  (_1.frozen? ? _1.dup : _1).add_parent(uri_type)
              } : uri_type
          else uri_type
          end
        when ::Regexp then
          # Return `nil` the first time we query a `Regexp`, ensuring it will run through `MrMIME` and load all matches.
          # This is to avoid inconsistent results in situations where we have already loaded some types which would match the `Regexp`,
          # e.g. if we have loaded `image/jpeg` and get a `Regexp` needle `/image/` we must still load all other `image/*` types.
          # Return a `::Set` to make sure we de-duplicate aliased CYOs where multiple of its CYIs match.
          all_night.values.keep_if { needle === _1.to_s }&.to_set if (
            nφ_crime.include?(needle.hash) or  # This needle has already been run through the dual XML parser loop.
            max_burning.eql?(0) and all_night.size > DEFAULT_TYPE_CACHE_SIZE  # …or guess that we've already loaded all data.
          )
        when ::String then
          # A `String` needle might represent a Media-Type name (e.g. `"image/jpeg"`), a `::Pathname`, or a `::URI`.
          uri_match = ::Addressable::URI::parse(needle)
          # NOTE: Even a plain `::String` will successfully `::parse` as a `URI`, so we must check the `#scheme`. For example:
          #       irb> ::Addressable::URI::parse('*.csv') => #<Addressable::URI:0x1a090 URI:*.csv>
          #       irb> ::Addressable::URI::parse('.csv') => #<Addressable::URI:0x1b210 URI:.csv>
          #       irb> ::Addressable::URI::parse('csv') => #<Addressable::URI:0x1c390 URI:csv>
          # NOTE: Make sure this logic matches what's in the generic `CHECKING::YOU::OUT()` entry-point method!
          if uri_match.nil? or uri_match.scheme.nil? then
            # The `String` needle is not a URI.
            all_night[::CHECKING::YOU::IN::from_iana_media_type(needle)].yield_self(&together_4ever)
          else remember_you.call(uri_match)
          end
        when ::Enumerable then
          # Don't `#map!` because it will change an `EverlastingMessage`'s content by reference.
          needle.map(&remember_you)
        end  # case needle
      }  # remember_you


      # Main message loop to process incoming `::Ractor` message queue for instructions.
      # This will block when the queue empties.
      # NOTE: `while case ::Ractor::receive` is syntactically valid, but it seems to stop executing
      #       part way through the `case` statement unless I assign it to a variable first and `case` that.
      while _message = ::Ractor::receive
        case _message
        in ::CHECKING::YOU::OUT     => cyo then remember_me.call(cyo.in, cyo)  # Memoize a new fully-loaded CYO.
        in ::CHECKING::YOU::IN      => cyi then mime_jr.send(cyi, move: true)  # Spool a type to load on the next XML parse.
        in ::CHECKING::YOU::IN      => cyi, ::CHECKING::YOU::OUT => cyo then remember_me.call(cyi, cyo)
        in ::CHECKING::YOU::IN::B4U => cyi, ::CHECKING::YOU::OUT => cyo then remember_me.call(cyi, cyo)
        in ::Float::INFINITY               then max_burning = 0  # No CYOs will be purged when loading more types.
        in ::Integer                => max then
          # We can't subclass `Integer`, because Ruby treats them as immediates instead of heap objects,
          # so our outer methods use negative `Integer` to affect the second of our two queues.
          case
          when max.positive? then max_burning =  max
          when max.negative? then how_long    = -max
          when max.zero?     then
            max_burning = 0
            how_long    = DEFAULT_QUERY_CACHE_SIZE
          end
        in DISCOVER_THE_LIFE::SharedMIMEinfo => mime_package
          # `::Pathname` subclass representing a `shared-mime-info`-format XML package. Toggle them in both parsers.
          mime_jr.send(mime_package)
          mr_mime.send(mime_package)
        in ::CHECKING::YOU::IN::EverlastingMessage => message then
          # An `EverlastingMessage` is a `::Struct` message we MUST respond to, either with a CYO, a `::Set` of CYOs, or `nil`.
          # We will fill in its `#response` member with the result of running its `#request` through our type-matching logic,
          # then send the mutated message to the `::Ractor` specified in its `#destination` member.
          i_member = last_message[message.in_motion.hash] || remember_you.call(message.in_motion)
          if nφ_crime.delete?(message.in_motion.hash) or not (
            # An `::Array` needle will come back as e.g. `[nil, nil]` if we need to load data.
            i_member.is_a?(::Enumerable) ? i_member.none? : i_member.nil?
          ) then
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
            max_burning = 0 if INFINITE_PRAYER.include?(message.in_motion)
            mime_jr.send(message, move: true)
            next
          end  # if nφ_crime.delete?(message.in_motion.hash) or not i_member.nil?

        else p "Unhandled `#{message.class}` message: #{message}"; next
        end  # case ::Ractor::receive
      end  # while
    }  # ::Ractor.new
  })  # NEW_AREA

  # `::Ractor` round-trip accessor methods for all Areas.
  include(::CHECKING::YOU::OUT::GHOST_REVIVAL::ROUND_AND_ROUND)

end  # module CHECKING::YOU::OUT::GHOST_REVIVAL
