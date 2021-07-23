require 'forwardable' unless defined? ::Forwardable
require 'pathname' unless defined? ::Pathname
require 'stringio' unless defined? ::StringIO


class CHECKING::YOU
  # Hash subclass to index our find-by-content byte-sequences.
  # Sequences define a Range of the byte boundaries where they might be found
  # in a hypothetical file/stream. Store them in nested Hashes,
  # e.g. {offset.min => {offset.max => {CatSequence[SequenceCat, …] => CHECKING::YOU::OUT }}}
  class MagicWithoutTears < ::Hash
    def new()
      super { |h,k| h[k] = self.class.new(&h.default_proc) }
    end

    # Automatically nest additional MWT Hashes when storing Sequences.
    # Rejected upstream, so we need to roll our own: https://bugs.ruby-lang.org/issues/11747
    def bury(*args)
      case args.count
        when 0, 1 then raise ArgumentError.new("Can't `bury` fewer than two arguments.")
        when 2 then self[args.first] = args.last
        else (self[args.shift] ||= self.class.new).bury(*args)
      end
      self
    end
  end  # class MagicWithoutTears
end  # class CHECKING::YOU


# Find-by-content file matching à la `libmagic` https://www.freebsd.org/cgi/man.cgi?query=magic&sektion=5
# Instance-level components.
module CHECKING::YOU::SweetSweet♥Magic

  attr_reader :cat_sequence

  # Take a weighted `CatSequence`, store it locally as a possible match for this CYO,
  # and memoize in classwide storage it for batch sequence matching.
  def add_content_match(action)
    ::CHECKING::YOU::INSTANCE_NEEDLEMAKER.call(:@cat_sequence, action, self)
    self.class.magic_without_tears.bury(action.min, action.max, action, self)
  end

  # Represent a container for multiple matching byte sequences along with a priority value
  # to use when there are multiple matches for a stream, in which case the highest `weight` wins.
  # Note: Array methods will return `Array` instead of `WeightedAction` since https://bugs.ruby-lang.org/issues/6087
  class SpeedyCat < ::Array

    include ::CHECKING::YOU::WeightedAction

    # Forward `Range`-like methods to our member Sequences.
    def min;     self.map(&:min).min; end
    def max;     self.map(&:max).max; end
    def minmax; [self.min, self.max]; end
    def size;    self.max - self.min; end

    # Match all-or-none member Sequences against some given bytes.
    # The `offset` parameter allows senders to provide a smaller-than-whole slice of input
    # without invalidating our members' `boundary`-from-start-of-stream.
    def =~(otra, offset: 0)
      self.each { |sequence_cat|
        return false unless sequence_cat =~ otra.slice(sequence_cat.min - offset, sequence_cat.size)
      }
      return true
    end

  end  # SpeedyCat


  # Represent one possible chain of byte sequences for a successful content match.
  SequenceCat = ::Struct.new(:sequence, :boundary, :mask) do

    # In our source XML the `<magic>` element is the one that has the `priority` weight,
    # not the `<match>` element which this `Struct` represents, but this `Struct`
    # should support weighting too so we can avoid allocating a spurious weighted container
    # when it would contain only one member (us), in which case a non-default `weight`
    # will be moved from the container to here.
    include ::CHECKING::YOU::WeightedAction

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
    def min
      case self[:boundary]
      when ::NilClass then 0
      when ::Integer  then self[:boundary]
      when ::Range    then self[:boundary].min
      else 0
      end
    end
    def max
      case self[:boundary]
      when ::NilClass then self[:sequence].size
      when ::Integer  then self[:boundary] + self[:sequence].size
      when ::Range    then self[:boundary].max
      else self[:sequence].size
      end
    end
    def minmax; [self.min, self.max]; end
    def size;    self.max - self.min; end

    # Match our embedded sequence against an arbitrary binary String.
    # The `offset` parameter isn't used here but needs to be defined so this `#=~`
    # and its custom `Array` container's `#=~` can be used interchangeably.
    def =~(otra, offset: 0)
      if self[:mask].nil? then
        return true if otra.include?(self[:sequence])
      else
        return true if (otra.to_i & self[:mask]).to_s(2).include?(self[:sequence])
      end
      return false
    end

  end  # SequenceCat
end  # module CHECKING::YOU::SweetSweet♥Magic


# Find-by-content file matching à la `libmagic`. Class-level components.
module CHECKING::YOU::SweetSweet♡Magic
  def magic_without_tears
    @magic_without_tears ||= ::CHECKING::YOU::MagicWithoutTears.new
  end

  # Main find-by-content matching code, externalized for reusability.
  # TODO: Find and fix all the bugs in this by running a test suite.
  # TODO: Profile this to reduce allocations.
  WILD_IO = proc {
    # TODO: Benchmark these buffer-size assumptions
    hold_my_hand = String.new(encoding: Encoding::ASCII_8BIT, capacity: 2048)
    quick_master = String.new(encoding: Encoding::ASCII_8BIT, capacity: 512)

    # Avoid re-allocating any data structure we can re-use between matches.
    the_last_striker = 0       # Previous iteration offset, used to calculate how many cached bytes to unshift.
    rolling_stops = Array.new  # Iteration end-points, to be sorted so we can pop the largest.
    rolling_stop = 0           # Iteration end-point, popped in a loop off an Array.
    come_with_me = Hash.new    # Successful matches to return.

    find_out = -> (wild_io) {
      wild_io.binmode if wild_io.respond_to?(:binmode)

      # The top level of keys are byte offsets at which we should start inspecting a stream, e.g:
      # irb> CHECKING::YOU::OUT::magic_without_tears.keys.sort
      # [0, 1, 2, 4, 5, 6, 7, 8, 10, 11, 12, 16, 20, 24, 28, 31, 36, 38, 40, 44, 60, 65, 72, 100,
      # 102, 128, 134, 242, 256, 257, 260, 522, 546, 640, 2080, 2089, 2108, 2112, 2114, 2121]
      #
      # They must be sorted before use because `Hash` returns them by insertion order.
      ::CHECKING::YOU::OUT::magic_without_tears.keys.sort.each { |rolling_start|

        # It's pretty likely that the end of one iteration will already read past the start of the next one.
        wild_io.seek(rolling_start - the_last_striker, whence=IO::SEEK_CUR) if rolling_start > wild_io.pos
        # Drop unnecessary leading bytes from start points we've already iterated beyond.
        hold_my_hand.slice!(rolling_start - the_last_striker)

        # The second level of keys are byte offsets marking the ends of the areas we will inspect, e.g.:
        # irb(main):004:0> CHECKING::YOU::OUT::magic_without_tears[256].keys.sort
        # => [260, 264, 265, 268, 271]
        #
        # Again, they must be sorted to avoid insertion order.
        rolling_stops = ::CHECKING::YOU::OUT::magic_without_tears[rolling_start].keys.sort
        # IO#read returns `nil` if we're at the end of the stream.
        break if wild_io.read(rolling_stops.last - rolling_start, hold_my_hand).nil?

        # Empty the stops out from highest to lowest.
        # This is already sorted so the `last` element is always the largest remaining.
        while rolling_stop = rolling_stops.pop do

          # { SweetSweet♥Magic::SpeedyCat or SequenceCat => CHECKING::YOU::OUT }
          ::CHECKING::YOU::OUT::magic_without_tears[rolling_start][rolling_stop].each_pair { |cat_sequence, cyo|

            # Each match possibility is composed of one or more sub-sequences, all of which must be matched.
            quick_master = hold_my_hand.slice(cat_sequence.min - rolling_start, cat_sequence.size)

            # Save the sequences as well as the Type if we have a match. We need to save the sequences so we can
            # compare their `weight` in the case of multiple positives. Providing the `offset` allows a
            # `SpeedyCat` `Array` to further slice the given bytes for its members, since those members
            # only know the `boundary` offset they want from the beginning of the entire stream.
            come_with_me.store(cat_sequence, cyo) if cat_sequence.=~(quick_master, offset: rolling_start)

            # Save the start point so we know how many bytes to drop off the front of our stream cache.
            the_last_striker = rolling_start

          }  # self.magic_without_tears[rolling_start][rolling_stop].each_pair
        end
      }  # self.magic_without_tears.keys.sort.each
      return (come_with_me.empty? ? nil : come_with_me.dup).tap { |out| come_with_me.clear }
    }  # find_out
    -> (wild_io) {
      return find_out.call(wild_io)
    }
  }.call

  # Apply the find-by-content matcher on various types of input.
  # For example, paths representing files need to be opened for reading.
  def from_content(unknown_io)
    case unknown_io
    when IO, StringIO  # `IO` is the parent class of `File`, among others.
      # Assume for now that we should not `#close` an IO we were directly given.
      unknown_io.advise(:sequential)
      return WILD_IO.call(unknown_io)
    when String, Pathname
      # File::open takes a path, but IO::open only takes a file descriptor.
      # The File handle will be closed as soon as we exit the block scope.
      File.open(unknown_io, mode: File::Constants::RDONLY|File::Constants::BINARY) do |wild_io|
        wild_io.advise(:sequential)
        return WILD_IO.call(wild_io)
      end
    else nil
    end
  end

end
