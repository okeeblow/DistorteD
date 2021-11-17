require(-'forwardable') unless defined?(::Forwardable)
require(-'pathname') unless defined?(::Pathname)
require(-'stringio') unless defined?(::StringIO)

require_relative(-'weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)


# Find-by-content file matching à la `libmagic` https://www.freebsd.org/cgi/man.cgi?query=magic&sektion=5
# Instance-level components.
module ::CHECKING::YOU::OUT::SweetSweet♥Magic


  # Read, write, and clear (respectively) a CYO's weighted filemagic sequences.
  attr_reader(:cat_sequence)
  def add_content_fragment(action); self.awen(:@cat_sequence, action); end
  def clear_content_fragments; self.remove_instance_variable(:@cat_sequence); end

  # Read, write, and clear (respectively) a CYO's weighted treemagic sequences.
  attr_reader(:mother_tree)
  def add_tree_branch(action); self.awen(:@mother_tree, action); end
  def clear_tree_branches; self.remove_instance_variable(:@mother_tree); end


  # Represent a container for multiple matching byte sequences or tree hierarchies along with a priority value
  # to use when there are multiple matches for a given `Object`, in which case the highest `weight` wins.
  # Note: Array methods will return `Array` instead of `WeightedAction` since https://bugs.ruby-lang.org/issues/6087
  class SpeedyCat < ::Array

    # Byte sequence matches can be weighted so a more-specific match can be chosen
    # from among matches for e.g. container formats.
    include(::CHECKING::YOU::OUT::WeightedAction)

    # Forward `Range`-like methods to our member Sequences.
    def min;     self.map(&:min).min; end
    def max;     self.map(&:max).max; end
    def minmax; [self.min, self.max]; end
    def size;    self.max - self.min; end

    # Match all-or-none member Sequences against some given bytes.
    # The `offset` parameter allows senders to provide a smaller-than-whole slice of input
    # without invalidating our members' `boundary`-from-start-of-stream.
    def =~(otra, offset: 0)
      return case otra
      when ::NilClass then false
      when ::String   then self.map { _1.=~(otra.slice(_1.min - offset, _1.size)) }.all?
      when ::IO       then self.map { _1.=~(otra, offset: offset) }.all?
      when ::Pathname then self.map { _1.=~(otra) }.all?
      else super
      end
    end

  end  # SpeedyCat


  # Represent one possible link in a chain of byte sequences for a successful content match.
  SequenceCat = ::Struct.new(:sequence, :boundary, :mask) do

    # In our source XML the `<magic>` element is the one that has the `priority` weight,
    # not the `<match>` element which this `Struct` represents, but this `Struct`
    # should support weighting too so we can avoid allocating a spurious weighted container
    # when it would contain only one member (us), in which case a non-default `weight`
    # will be moved from the container to here.
    include(::CHECKING::YOU::OUT::WeightedAction)

    # We get the raw sequence and the sequence format attributes in separate callbacks
    # due to the way Ox works, and I can't assume deterministric callback order.
    # Use one attr_writer for the sequence, one for the format, and store the intermediate value
    # directly in `self[:sequence]` so we don't allocate outside an RValue with instance vars.
    def cat=(cat);       self[:sequence] = self[:sequence].nil? ? cat    : -self[:sequence].call(cat);    end
    def format=(format); self[:sequence] = self[:sequence].nil? ? format : -format.call(self[:sequence]); end

    # "The byte offset(s) in the file to check. This may be a single number or a range in the form `start:end',
    # indicating that all offsets in the range should be checked. The range is inclusive."
    def boundary=(range_string)
      return if range_string.nil?
      # I used to explicitly `String#split` on ':' here, but `#split` always allocates
      # even if it ends up splitting dedupable `String`s, so avoid it if possible.
      self[:boundary] = range_string.include?(-?:)      ?
        Range.new(*range_string.split(-?:).map(&:to_i)) :
        range_string.to_i
    end

    # Implement `Range`-like methods without necessarily having to allocate a new `Range`.
    #
    # Returns the beginning byte offset for where this sequence should be found in a hypothetical file/stream:
    def min
      case self[:boundary]
      when ::NilClass then 0
      when ::Integer  then self[:boundary]
      when ::Range    then self[:boundary].min
      else 0
      end
    end
    # Returns the end byte offset for where this sequence should be found in a hypothetical file/stream:
    def max
      case self[:boundary]
      when ::NilClass then self[:sequence].size
      when ::Integer  then self[:boundary] + self[:sequence].size
      when ::Range    then self[:boundary].max
      else self[:sequence].size
      end
    end
    # Returns both of the above:
    def minmax; [self.min, self.max]; end
    # …and the width in bytes of the possible search area.
    def size;    self.max - self.min; end

    # Match our embedded sequence against an arbitrary binary String.
    # The `offset` parameter isn't used here but needs to be defined so this `#=~`
    # and its custom `Array` container's `#=~` can be used interchangeably.
    def =~(otra, offset: 0)
      return case otra
      when ::NilClass then false
      when ::String then
        if self[:mask].nil? then
          otra.include?(self[:sequence])
        else
          (otra.to_i & self[:mask]).to_s(2).include?(self[:sequence])
        end
      when ::IO then
        otra.seek(self.min, whence=IO::SEEK_SET)
        self.=~(otra.read(self.size), offset: offset)
      else false
      end
    end

  end  # SequenceCat


  # Represent one possible link in a chain of tree branches for a successful directory match.
  #
  # "`<treemagic>` elements contain a list of `<treematch>` elements, any of which may match,
  #  and an optional `priority` attribute for all of the contained rules.
  #  The default priority value is `50`, and the maximum is `100`."
  #
  # "`<treematch>` elements can be nested, meaning that both the outer
  #  and the inner `<treematch>` must be satisfied for a 'match'."
  #
  # We avoid nesting by transforming the element trees into multiple flat `Array`s,
  # i.e. instances of this `Class` inside a `SpeedyCat`, or a single instance of this `Class`
  # on its own if there's only one level of `<treematch>` elements where the container would be a waste.
  CosmicCat = ::Struct::new(:here_we_are, :your_body, :case_sensitive, :executable, :non_empty, :inner_spirit) do
    include(::CHECKING::YOU::OUT::WeightedAction)

    # "A path that must be present on the mounted volume/filesystem.
    #  The path is interpreted as a relative path starting at the root of the tested volume/filesystem."
    def here_we_are=(otra)
      self[:here_we_are] = case otra
        when ::Pathname then otra
        when ::String   then ::Pathname::new(otra)
      end
    end

    # "The type of path. Possible values: `file`, `directory`, `link`"
    #
    # Avoid calling this `type` like in the XML since that's an overloaded term.
    def your_body=(otra)
      self[:your_body] = case otra
        when ::File, -'file',      :file      then :file
        when ::Dir,  -'directory', :directory then :directory
        when         -'link',      :link      then :link
      end
    end

    # "The mimetype for the file at path"
    #
    # Avoid calling this `mimetype` like in the XML since that's an overloaded term.
    def inner_spirit=(otra)
      self[:inner_spirit] = case otra
        when ::CHECKING::YOU::IN then otra
        when ::String            then ::CHECKING::YOU::IN::from_ietf_media_type(otra)
      end
    end

    # Many `<treematch>` elements will have these unset. Return a false default for `nil`s.
    def executable?;     self[:executable]     || false; end
    def case_sensitive?; self[:case_sensitive] || false; end
    def non_empty?;      self[:non_empty]      || false; end

    # Match this structure against a `::Pathname` representing an extant directory.
    #
    # NOTE the official `Dir::glob` documentation about how "`File::FNM_CASEFOLD` is ignored" in `Dir::glob`,
    #      i.e. we can't use it to perform a case-insensitive match like with `File::fnmatch`.
    #      This is supported by the documentation for the constant itself:
    #      "Makes `File.fnmatch` patterns case insensitive (but not `Dir.glob` patterns)"
    #
    # Several forum and blog posts disagree with the official documentation and claim it works fine:
    # https://lostechies.com/derickbailey/2011/04/14/case-insensitive-dir-glob-in-ruby-really-it-has-to-be-that-cryptic/
    # https://www.ruby-forum.com/t/case-sensitivity-in-glob-revisited/110780/4
    # https://www.ruby-forum.com/t/whats-up-with-dir-glob/209794/5
    # https://www.ruby-forum.com/t/file-fnm-casefold-doesnt-work-for-dir-glob/98408/2
    #
    # However when I was developing `<treemagic>` support I couldn't get the `FNM_CASEFOLD` flag to work
    # and realized the documentation might be correct after all:
    #   irb> lumix = Pathname::new('/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/TEST MY BEST/Try 2 Luv. U/x-content/image-dcf/LUMIX')
    #   irb> Dir::glob(Pathname::new('dcim'), File::FNM_CASEFOLD, base: lumix) => []
    #   irb> Dir::glob(Pathname::new('DCIM'), File::FNM_CASEFOLD, base: lumix) => ["DCIM"]
    #   irb> Dir::glob(Pathname::new('dcim*'), File::FNM_CASEFOLD, base: lumix) => ["DCIM"]
    #
    # Notice how it *does* work with the addition of the trailing asterisk to the pattern!
    # It works for multi-level patterns as well, but only if *every level* is given an asterisk:
    #   irb> svcd = Pathname::new('/home/okeeblow/Works/DistorteD/CHECKING YOU OUT/TEST MY BEST/Try 2 Luv. U/x-content/video-svcd/CYO-SVCD')
    #   irb> Dir::glob(Pathname::new('MPEG2/AVSEQ01.MPG'), File::FNM_CASEFOLD, base: svcd) => []
    #   irb> Dir::glob(Pathname::new('MPEG2/AVSEQ01.MPG*'), File::FNM_CASEFOLD, base: svcd) => []
    #   irb> Dir::glob(Pathname::new('MPEG2*/AVSEQ01.MPG*'), File::FNM_CASEFOLD, base: svcd) => ["mpeg2/avseq01.mpg"]
    #
    #
    # What gives? Time to delve into MRI source to find out:
    # - https://github.com/ruby/ruby/blob/master/dir.rb
    # - https://github.com/ruby/ruby/blob/master/dir.c
    #
    # In `dir.rb` we can see the method definition for `self.glob` and how it's just a Ruby-land wrapper
    # for `Primitive.dir_s_glob(pattern, flags, base, sort)`, meaning the `dir_s_glob` method defined in `dir.c`.
    #
    # Inside `dir_s_glob` we can see the bitwise operation disabling the `CASEFOLD` flag if it was given:
    # `const int flags = (NUM2INT(rflags) | dir_glob_option_sort(sort)) & ~FNM_CASEFOLD;`.
    # That is the "bitwise NOT (one's complement)" operator: https://en.wikipedia.org/wiki/Bitwise_operations_in_C#Bitwise_operators
    #
    # So why does it work with an asterisk added to the pattern? The following is speculation since this is
    # a difficult flow to follow, but here's what I think might be going on:
    #
    # Depending on if it was given a `String` glob pattern or an `Array` of patterns, `dir_s_glob` calls
    # either `rb_push_glob` or `dir_globs`. Both of those methods end up calling the `push_glob` method.
    #
    # If the current-working-directory (or the given `base:` directory) exists, `push_glob` calls `ruby_glob0`.
    # `ruby_glob0` expands any brace syntax in the pattern then calls `glob_make_pattern` to convert the
    # pattern `String` to a `glob_pattern`, a C `struct` which wraps the pattern `char*` along with a `glob_pattern_type`:
    # `enum glob_pattern_type { PLAIN, ALPHA, BRACE, MAGICAL, RECURSIVE, MATCH_ALL, MATCH_DIR }`.
    #
    # If the pattern is not "recursive" (uses the '**' directory-descending pattern), `glob_make_pattern` calls
    # `has_magic` to determine the other attributes for the pattern. Inside `has_magic`, the `MAGICAL` attribute is set
    # if the pattern contains the characters '*', '?', or '[' (EXTGLOB) but does not contain a '{' (`BRACE`).
    #
    # Back in `ruby_glob0`, the new `glob_pattern` is used when calling `glob_helper` to get the actual globbed directory contents.
    # Inside `glob_helper`, the `MAGICAL` `glob_make_pattern` makes us skip the short-circuit `goto literally`
    # in `if (!(norm_p || magical || recursive))`, then we hit a volume capabilities check in `is_case_sensitive` which,
    # if true, re-adds the `CASEFOLD` flag: `flags |= FNM_CASEFOLD` and is why adding the asterisk makes this work!
    #
    # TODO: Identify optical media for `x-content/blank-cd`, `x-content/blank-dvd`, `x-content/blank-bd`, and `x-content/blank-hddvd`.
    # TODO: Identify USB devices for e.g. `x-content/audio-player`.
    def =~(otra)
      return if self.here_we_are.nil?
      case otra
      when ::Pathname then
        ::Dir::glob(
          self.case_sensitive? ?
            self[:here_we_are] :
            self[:here_we_are].to_s.split(::File::SEPARATOR).map!{ _1 << -?* }.join(::File::SEPARATOR),
          ::File::FNM_DOTMATCH | ::File::FNM_EXTGLOB | (self.case_sensitive? ? 0 : ::File::FNM_CASEFOLD),
          base: otra,
        ).pop&.yield_self(&otra.method(:join))&.yield_self { |globbed|
          # If we get here, the file/directory/link exists and has passed case-sensitivity check.
          case self.your_body
          when :file      then globbed.file?
          when :directory then globbed.directory?
          when :link      then globbed.symlink?
          end.tap { |match|
            match = globbed.executable? if self.executable?
            match = !globbed.empty?     if self.non_empty?
            # TODO: `mimetype`/`inner_spirit` matching — requires `together_4ever` to enrich this member to a `CYO`.
          }
        }
      else super
      end
    end  # =~

  end  # CosmicCat

end  # module CHECKING::YOU::SweetSweet♥Magic


# Find-by-content file matching à la `libmagic`. Class-level components.
module ::CHECKING::YOU::OUT::SweetSweet♡Magic

  MAGIC_WITHOUT_TEARS = Ractor.make_shareable(proc {
    # Hash subclass to index our find-by-content byte-sequences.
    # Sequences define a Range of the byte boundaries where they might be found
    # in a hypothetical file/stream. Store them in nested Hashes,
    # e.g. {offset.min => {offset.max => {CatSequence[SequenceCat, …] => CHECKING::YOU::OUT }}}
    ::Class.new(::Hash).tap {
      _1.define_method(:new) {
        super { |h,k| h[k] = self.class.new(&h.default_proc) }
      }

      # Automatically nest additional MWT Hashes when storing Sequences.
      # Rejected upstream, so we need to roll our own: https://bugs.ruby-lang.org/issues/11747
      _1.define_method(:bury) { |*args|
        case args.count
          when 0, 1 then raise ::ArgumentError.new("Can't `bury` fewer than two arguments.")
          when 2 then
            if self.has_key?(args.first) then
              if self.fetch(args.first).is_a?(::Array) then
                self.fetch(args.first).push(args.last) unless self.fetch(args.first).include?(args.last)
              else
                self.store(args.first, ::Array[self.fetch(args.first), args.last]) unless self.fetch(args.first).eql?(args.last)
              end
            else
              self.store(args.first, args.last)
            end
          else (self[args.shift] ||= self.class.new).bury(*args)
        end
        self
      }

      # Do the reverse of `:bury`, deleting objects and empty keys while walking up to the root.
      _1.define_method(:baleet) { |*haystack, needle|
        return unless haystack.size > 0
        lower_world = haystack.slice(...-1)
        case self.dig(*haystack)
        in ::NilClass then break
        in ::Array => tip then
          if tip.empty? and not lower_world.empty? then
            self.dig(*lower_world)&.delete(tip)
          else tip.delete(needle)
          end
        in ::Hash => tip then
          if tip.empty? and not lower_world.empty? then
            self.dig(*lower_world)&.delete(haystack.last)
          else tip.delete_if { |i| i === needle }
          end
        in needle => tip then
          self.dig(*lower_world)&.delete(haystack.last) unless lower_world.empty?
        end
        self.baleet(*haystack)
      }

      # Set up scratch variables for content matching.
      _1.define_method(:initialize) {
        self.instance_variable_set(:@rolling_start, ::Array.new)
        self.instance_variable_set(:@rolling_stop,  ::Array.new)
        self.instance_variable_set(:@hold_my_hand,  ::String.new(encoding: ::Encoding::ASCII_8BIT, capacity: 2048))
        self.instance_variable_set(:@quick_master,  ::String.new(encoding: ::Encoding::ASCII_8BIT, capacity: 512))
        super()
      }

      # Define a `WeightedAction`-capable sub-sub-class of `::Hash` as our return container for search results.
      _1.const_set(:COME_WITH_ME, ::Class.new(::Hash).tap { |cwm|
        cwm.define_method(:push_up) {
          self.select { |(k,_v)|
            k.weight >= self.keys.max.weight
          }.values.flatten.first
        }
      })

      # Match a given `IO` stream against all of our loaded types.
      _1.define_method(:so_below) { |wild_io|
        return if wild_io.nil?

        # Disable newline- and encoding-conversion. The stream will be `Encoding::ASCII_8BIT`.
        wild_io.binmode if wild_io.respond_to?(:binmode)

        # We may have been given a stream at a later-than-zero position,
        # and our matching code assumes the stream starts at zero.
        wild_io.rewind unless wild_io.pos = 0

        the_last_striker = 0
        come_with_me = self.singleton_class.const_get(:COME_WITH_ME).new

        # The top level of keys are byte offsets at which we should start inspecting a stream, e.g:
        # irb> CHECKING::YOU::OUT::magic_without_tears.keys.sort
        # [0, 1, 2, 4, 5, 6, 7, 8, 10, 11, 12, 16, 20, 24, 28, 31, 36, 38, 40, 44, 60, 65, 72, 100,
        # 102, 128, 134, 242, 256, 257, 260, 522, 546, 640, 2080, 2089, 2108, 2112, 2114, 2121]
        #
        # They must be sorted before use because `Hash` returns them by insertion order.
        self.instance_variable_get(:@rolling_start).push(*self.keys.sort_by! { |k| -k })
        while rolling_start = self.instance_variable_get(:@rolling_start).pop

          # It's pretty likely that the end of one iteration will already read past the start of the next one.
          wild_io.seek(rolling_start, whence=::IO::SEEK_SET) if rolling_start > wild_io.pos
          # Drop unnecessary leading bytes from start points we've already iterated beyond.
          self.instance_variable_get(:@hold_my_hand).slice!(rolling_start - the_last_striker)

          # The second level of keys are byte offsets marking the ends of the areas we will inspect, e.g.:
          # irb(main):004:0> CHECKING::YOU::OUT::magic_without_tears[256].keys.sort
          # => [260, 264, 265, 268, 271]
          #
          # Again, they must be sorted to avoid insertion order.
          self.instance_variable_get(:@rolling_stop).push(*self[rolling_start].keys.sort!)

          # IO#read returns `nil` if we're at the end of the stream. Bail out if so.
          # Note that this is not just a guard statement and reads the stream into `:hold_my_hand` for use.
          break if wild_io.read(
            self.instance_variable_get(:@rolling_stop).last - rolling_start,
            self.instance_variable_get(:@hold_my_hand)
          ).nil?

          # Empty the stops out from highest to lowest.
          # This is already sorted so the `last` element is always the largest remaining.
          while rolling_stop = self.instance_variable_get(:@rolling_stop).pop do

            # { SweetSweet♥Magic::SpeedyCat or SequenceCat => CHECKING::YOU::OUT }
            # Use the lonely operator since this could be `nil` if an older loaded type was purged.
            self[rolling_start][rolling_stop]&.each_pair { |cat_sequence, cyo|

              # Each match possibility is composed of one or more sub-sequences, all of which must be matched.
              self.instance_variable_get(:@quick_master).replace(
                self.instance_variable_get(:@hold_my_hand).slice(cat_sequence.min - rolling_start, cat_sequence.size)
              )

              # Save the sequences as well as the Type if we have a match. We need to save the sequences so we can
              # compare their `weight` in the case of multiple positives. Providing the `offset` allows a
              # `SpeedyCat` `Array` to further slice the given bytes for its members, since those members
              # only know the `boundary` offset they want from the beginning of the entire stream.
              come_with_me.store(cat_sequence, cyo) if cat_sequence.=~(
                self.instance_variable_get(:@quick_master),
                offset: rolling_start,
              )

              # Save the start point so we know how many bytes to drop off the front of our stream cache.
              the_last_striker = rolling_start

            }  # self.magic_without_tears[rolling_start][rolling_stop].each_pair
          end  # while rolling_stop = @rolling_stop.pop
        end  # while rolling_start = @rolling_start.pop

        return come_with_me
      }
    }
  })

end
