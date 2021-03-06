require 'set' unless defined? ::Set
require 'pathname' unless defined? ::Pathname


# This file defines/imports various utility Modules/procs/etc that should be available
# to all other CYO components without `including`/`extending`.
require_relative 'party_starter/weighted_action' unless defined? ::CHECKING::YOU::WeightedAction
require_relative 'party_starter/stick_around' unless defined? ::CHECKING::YOU::StickAround

class CHECKING::YOU

  # The following two `proc`s handle classwide-memoization and instance-level assignment
  # for values that may be Enumerable but often refer to only a single Object.
  #
  # For example, most `Postfix`es (file extensions) will only ever belong to a single CYO Object,
  # but a handful represent possibly-multiple types, like how `.doc` can be an MSWord file or WordPad RTF.
  #
  # These assignment procs take a storage haystack, a needle to store, and the CYO receiver to which the needle refers.
  # They will set `haystack[needle] => CYO` if that needle is unique and unset, or they will convert
  # an existing single `haystack[needle] => CYO` assignment to `haystack[needle] => Set[existingCYO, newCYO]`.
  #
  # This is an admittedly-annoying complexity-for-performance tradeoff with the goal of allocating
  # as few spurious containers as possible instead of explicitly initializing a Set for every needle
  # when most of them would wastefully be a Set of just a single thing.
  CLASS_NEEDLEMAKER = proc { |haystack, needle, receiver|
    # Create the container if this is the very first invocation.
    receiver.class.instance_variable_set(haystack, Hash.new(nil)) unless receiver.class.instance_variable_defined?(haystack)

    # Set the `haystack` Hash's `needle` key to the `receiver` if the `key` is unset, otherwise
    # to a `Set` of the existing value plus `receiver` if that value is not `receiver` already.
    receiver.class.instance_variable_get(haystack).tap { |awen|
      case awen[needle]
      when nil then awen[needle] = receiver
      when ::Set then awen[needle].add(receiver)
      when receiver.class then awen[needle] = Set[awen[needle], receiver] unless awen[needle] == receiver
      end
    }
  }

  # This is the instance-level version of the above, e.g. a CYO with only one Postfix
  # will assign `cyo.:@postfixes = Postfix`, and a CYO with many Postfixes will assign
  # e.g. `cyo.:@postfixes = Set[post, fix, es, …]`.
  INSTANCE_NEEDLEMAKER = proc { |haystack, needle, receiver|
    if receiver.instance_variable_defined?(haystack) then
      receiver.instance_variable_get(haystack).add(needle)
    else
      receiver.instance_variable_set(haystack, Set[needle])
    end
  }


  # Test a Pathname representing an extant file whose contents and metadata we can use.
  # This is separated into a lambda due to the complexity, since the entry-point might
  # be given a String that could represent a Media Type, a hypothetical path,
  # an extant path, or even raw stream contents. It could be given a Pathname representing
  # either a hypothetical or extant file. It could be given an IO/Stream object.
  # Several input possibilities will end up callin this lambda.
  #
  # Some of this complexity is my fault, since I'm doing a lot of variable juggling
  # to avoid as many new-Object-allocations as possible in the name of performance
  # since this library is the very core-est core of DistorteD;
  # things like assigning Hash values to single CYO objects the first time that key is stored
  # then replacing that value with a Set iff that key needs to reference any additional CYO.
  #
  # - `::from_xattr` can return `nil` or a single `CYO` depending on filesystem extended attributes.
  #   It is very very unlikely that most people will ever use this, but I think it's cool 8)
  #
  # - `::from_postfix` can return `nil`, `CYO`, or `Set` since I decided to store Postfixes
  #   separately from freeform globs since file-extension matches are the vast majority of globs.
  #   Postfixes avoid needing to be weighted since they all represent the same final pathname component
  #   and should never result in multiple conflicting Postfix key matches.
  #   A single Postfix key can represent multiple CYOs, though; hence the possible `Set`.
  #
  # - `::from_glob` can return `nil` or `Hash` since even a single match will include the weighted key.
  #
  # - `::from_content` can return `nil` or `Hash` based on a `libmagic`-style match of file/stream contents.
  #   Many common types can be determined from the first four bytes alone, but we support matching
  #   arbitrarily-long sequences against arbitrarily-big byte range boundaries.
  #   These keys will also be weighted, even for a single match.
  TEST_EXTANT_PATHNAME = -> (pathname, so_deep: true, only_one_match: true) {

    # Never return empty Enumerables.
    # Yielding-self to this proc will `nil`-ify anything that's `:empty?`
    # and will pass any non-Enumerable Objects through.
    point_zero = proc { _1.respond_to?(:empty) ? (_1.empty? ? nil : _1) : _1 }

    # Our matching block will return a single CYO when possible, and can optionally
    # return multiple CYO matches for ambiguous files/streams.
    # Multiple matching must be opted into with `only_one_match: false` so it doesn't need to be
    # checked by every caller that's is fine with best-effort and wants to minimize allocations.
    one_or_eight = proc { |huh|
      case
      when huh.nil? then nil
      when huh.respond_to?(:empty?), huh.respond_to?(:first?)
        if huh.empty? then nil
        elsif huh.size == 1 then huh.is_a?(::Hash) ? huh.values.first : huh.first
        elsif huh.size > 1 and only_one_match then huh.is_a?(::Hash) ? huh.values.first : huh.first
        else huh
        end
      else huh
      end
    }

    # Test all "glob" matches against all child Types of all "magic" matches to allow for
    # nuanced detection of ambiguous streams where a `magic` match returns multiple possibilities,
    # e.g. using a `.doc` Postfix-match to choose a `text-plain` glob-match for non-Word `.doc` files
    #      or to choose a `application/msword` glob-match over a more generic `application/x-ole-storage`
    #      magic-match when the magic weights alone are not enough information to make the correct choice.
    # irb> ::CHECKING::YOU::OUT::from_postfix('doc')
    # => #<Set: {#<CHECKING::YOU::OUT application/msword>, #<CHECKING::YOU::OUT text/plain>}>
    #
    # Again, a lot of the complexity here is "my fault" in that I could avoid it by explicitly using
    # the same data structures for all the different inputs, but I need this to be as fast
    # and as low-overhead as possible which means avoiding allocations of things like
    # Enumerables that end up holding only a single other object.
    # Obviously that leads to a lot of variation in result values from helper methods,
    # so I'll own that here instead of ever making callsites deal with it.
    #
    # This `proc`'s output will introduce a little more of that same complexity since it will be `nil`
    # if either input is `nil`, will be a single CYO if there is only one union match,
    # or a `Set` if there are still multiple possibilities.
    magic_children = proc { |glob, magic|
      # NOTE: CYO deviates from `shared-mime-info`'s behavior very slightly here!
      #
      # `shared-mime-info`'s "Recommended checking order" documentation sez:
      # "If any of the mimetypes resulting from a glob match is equal to or a subclass of the result
      #  from the magic sniffing, use this as the result. This allows us for example to distinguish text files
      #  called 'foo.doc' from MS-Word files with the same name, as the magic match for the MS-Word file would be 
      #  `application/x-ole-storage` which the MS-Word type inherits."
      #
      # Our behavior is identical except it allows glob matches which are a *superclass* of a
      # magic-match in addition to subclass or equal-to, i.e. using `:family_tree` for comparison here
      # instead of using `:kids_table`. There might be a downside to this that I haven't found yet
      # but it allows CYO to better match some things, e.g. matching a `'.flv'` video file as
      # `'video/x-flv'` instead of as `'video/x-javafx'`, since fd.o has the latter as a subclass of the former.
      case [glob, magic]
        in ::NilClass,           *                    then nil
        in *,                    ::NilClass           then nil
        in ::Set,                ::Hash               then glob & magic.values.to_set.map(&:family_tree).reduce(&:&)
        in ::Set,                ::CHECKING::YOU::OUT then glob & magic.kids_table
        in ::Hash,               ::Hash               then glob.values.to_set & magic.values.to_set.map(&:family_tree).reduce(&:&)
        in ::CHECKING::YOU::OUT, ::Hash               then magic.values.to_set.map(&:family_tree).reduce(&:&)&.include?(glob) ? glob : nil
        in ::Hash,               ::CHECKING::YOU::OUT then glob.values.to_set & magic.kids_table
        in ::CHECKING::YOU::OUT, ::CHECKING::YOU::OUT then glob == magic ? glob : nil
        else nil
      end.yield_self(&point_zero)
    }

    # "If a MIME type is provided explicitly (eg, by a ContentType HTTP header, a MIME email attachment,
    #  an extended attribute or some other means) then that should be used instead of guessing."
    # This will probably always be `nil` since this is a niche feature, but we have to test it first.
    ::CHECKING::YOU::OUT::from_xattr(pathname) || begin

      # "Start by doing a glob match of the filename. Keep only globs with the biggest weight."
      # "If the patterns are different, keep only matched with the longest pattern."
      #  If after this, there is one or more matching glob, and all the matching globs result in
      #  the same mimetype, use that mimetype as the result."
      # This can be `nil`, `CYO`, a `Set` of Postfix matches, or a `Hash` of weighted Glob matches.
      glob_matched = ::CHECKING::YOU::OUT::from_pathname(pathname)

      # "If the glob matching fails or results in multiple conflicting mimetypes,
      # read the contents of the file and do magic sniffing on it.
      # This can be `nil` or a `Hash` of weighted magic matches.
      magic_matched = (glob_matched.nil? || glob_matched.is_a?(Enumerable) || so_deep) ? ::CHECKING::YOU::OUT::from_content(pathname) : nil

      # Make a decision based on the two possible matches above plus a third match category
      # based on a union between the glob match and all children of all magic matches.
      # See the relevant proc above. Its result will always be `nil` if either input is `nil`.
      #
      # "If there was no glob match, use the magic match as the result."
      # "Otherwise use the result of the glob match that has the highest weight."
      return case [glob_matched, magic_matched, magic_children.call(glob_matched, magic_matched)]
        in ::NilClass,           ::Hash,     ::NilClass                            then LEGENDARY_HEAVY_GLOW.call(magic_matched, :weight)
        in ::CHECKING::YOU::OUT, ::NilClass, ::NilClass                            then glob_matched
        in ::Set,                ::NilClass, ::NilClass                            then glob_matched
        in ::Hash,               ::NilClass, ::NilClass                            then LEGENDARY_HEAVY_GLOW.call(glob_matched, [:weight, :length])
        in *,                                ::CHECKING::YOU::OUT => only_one_type then only_one_type
        in ::Set,                ::Hash,     ::Set => magic_children               then
          # Choose the union-matched type having the the heaviest magic-matched weight.
          LEGENDARY_HEAVY_GLOW.call(magic_matched.keep_if { |_magic, cyo| magic_children.include?(cyo) }, :weight)
        in ::Hash,               ::Hash,     ::Set => magic_children               then
          # Choose the union-matched type having the heaviest glob-matched weight,
          # and then additionally the longest glob string if there are still multiple matches.
          LEGENDARY_HEAVY_GLOW.call(glob_matched.keep_if { |_glob, cyo| magic_children.include?(cyo) }, [:weight, :length])
        in ::CHECKING::YOU::OUT, ::Hash,     ::NilClass                            then glob_matched
        in ::CHECKING::YOU::OUT, ::Hash,     ::Set => magic_children               then
          # Choose the single glob-matched type iff it was also magic-matched,
          # otherwise choose the heaviest magic-matched type.
          magic_matched.values.include?(glob_matched) ? glob_matched : LEGENDARY_HEAVY_GLOW.call(magic_matched, :weight)
        in ::NilClass,           ::NilClass, ::NilClass                            then
          # "If no magic rule matches the data (or if the content is not available),
          #  use the default type of application/octet-stream for binary data, or text/plain for textual data."
          # "Note: Checking the first 128 bytes of the file for ASCII control characters is a good way to guess
          #  whether a file is binary or text, but note that files with high-bit-set characters should still be
          #  treated as text since these can appear in UTF-8 text, unlike control characters.
          ::CHECKING::YOU::OUT::from_ietf_media_type('application/octet-stream')
        else nil
      end.yield_self(&one_or_eight)
    end  # ::CHECKING::YOU::OUT::from_xattr(pathname) || begin
  }  # TEST_EXTANT_PATHNAME

end  # class CHECKING::YOU
