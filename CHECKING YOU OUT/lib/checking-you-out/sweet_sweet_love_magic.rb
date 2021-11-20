
# Generic `Array` subclass for other file-matchable structures.
require_relative(-'sweet_sweet_love_magic/speedy_cat') unless defined?(::CHECKING::YOU::OUT::SweetSweet♥Magic::SpeedyCat)

# Find-by-bytes file matching à la `libmagic` https://www.freebsd.org/cgi/man.cgi?query=magic&sektion=5
require_relative(-'sweet_sweet_love_magic/sequence_cat') unless defined?(::CHECKING::YOU::OUT::SweetSweet♥Magic::SequenceCat)

# Find-by-directory-tree matching.
require_relative(-'sweet_sweet_love_magic/cosmic_cat') unless defined?(::CHECKING::YOU::OUT::SweetSweet♥Magic::CosmicCat)

# Find-by-XML-namespace matching.
require_relative(-'sweet_sweet_love_magic/re_roots') unless defined?(::CHECKING::YOU::OUT::SweetSweet♥Magic::ReRoots)


# Find-by-content CYO instance-level components.
module ::CHECKING::YOU::OUT::SweetSweet♥Magic

  # Read, write, and clear (respectively) a CYO's weighted filemagic sequences.
  attr_reader(:cat_sequence)
  def add_content_fragment(fragment); self.awen(:@cat_sequence, fragment); end
  def clear_content_fragments; self.remove_instance_variable(:@cat_sequence); end

  # Read, write, and clear (respectively) a CYO's weighted treemagic sequences.
  attr_reader(:mother_tree)
  def add_tree_branch(branch); self.awen(:@mother_tree, branch); end
  def clear_tree_branches; self.remove_instance_variable(:@mother_tree); end

  attr_reader(:re_roots)
  def add_xml_root(root); self.awen(:@re_roots, root); end
  def clear_xml_roots; self.remove_instance_variable(:@re_roots); end

end  # module CHECKING::YOU::SweetSweet♥Magic


# Find-by-content CYO `Class`-level components.
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
