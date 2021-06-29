require 'forwardable' unless defined? ::Forwardable
require 'pathname' unless defined? ::Pathname
require 'stringio' unless defined? ::StringIO

# Find-by-content file matching à la `libmagic`.
# https://www.freebsd.org/cgi/man.cgi?query=magic&sektion=5

class CHECKING::YOU
  class MagicWithoutTears < ::Hash
    def new()
      super { |h,k| h[k] = self.class.new(&h.default_proc) }
    end

    def bury(*args)
      case args.count
      when 0, 1 then
        # nope.avi
      when 2 then
        self[args.first] = args.last
      else
        arg = args.shift
        self[arg] = self.class.new unless self[arg]
        self[arg].bury(*args) unless args.empty?
      end
      self
    end
  end  # class MagicWithoutTears
end  # class CHECKING::YOU


module CHECKING::YOU::SweetSweet♥Magic

  attr_reader :cat_sequence

  # Take a weighted `CatSequence`, store it locally as a possible match for this CYO,
  # and memoize in classwide storage it for batch sequence matching.
  def add_content_match(action)
    self.class.magic_without_tears.bury(*(action.boundary.minmax), action, self)
  end

  # Represent a container for multiple matching byte sequences along with a priority value
  # to use when there are multiple matches for a stream, in which case the highest `weight` wins.
  # Note: Array methods will return `Array` instead of `WeightedAction` since https://bugs.ruby-lang.org/issues/6087
  class CatSequence < ::Array

    include ::CHECKING::YOU::WeightedAction

    # Get the maximum boundary Range for the sum of all sequences in our Array,
    # e.g. self[SC(5..10), SC(12..20), SC(256..512)] => (5..512)
    def boundary
      self                                             # Our subclassed Array
      .select(&SequenceCat.method(:===))               # …which should only contain our Sequence structs but let's make sure
      .map(&:boundary)                                 # …because `SequenceCat` has its own `:boundary` method
      .map(&:minmax)                                   # …from which we can get all of their low and high boundaries
      .transpose                                       # …then partition all the minimums and all the maximums
      .yield_self { |(i,a)| Range.new(i.min, a.max) }  # …and construct a new Range bounded by the miniest min and maxiest max.
    end

    # Forward Range methods to `self.boundary`: https://ruby-doc.org/core/Range.html
    # Not forwarding `#count` since that's more appropriate for our subclassed Array.
    extend Forwardable
    def_instance_delegators(:boundary, :min, :max, :minmax, :size)

  end  # WeightedAction


  # Represent one possible chain of byte sequences for a successful content match.
  SequenceCat = ::Struct.new(:sequence, :boundary, :mask) do

    # We get the raw sequence and the sequence format attributes in separate callbacks
    # due to the way Ox works, and I can't assume deterministric callback order.
    # Use one attr_writer for the sequence, one for the format, and store the intermediate value
    # directly in `self[:sequence]` so we don't allocate outside an RValue with instance vars.
    def cat=(cat);       self[:sequence] = self[:sequence].nil? ? -cat    : self[:sequence].call(cat).b;    end
    def format=(format); self[:sequence] = self[:sequence].nil? ? format : format.call(self[:sequence]).b; end

    # "The byte offset(s) in the file to check. This may be a single number or a range in the form `start:end',
    # indicating that all offsets in the range should be checked. The range is inclusive."
    def boundary=(range_string)
      return if range_string.nil?
      self[:boundary] = range_string.split(-?:).map(&:to_i).yield_self { |boundaries|
        # `first` and `last` will be the same element if there was no ':' to split on.
        Range.new(boundaries.first, boundaries.last, exclude_end=false)
      }
    end

    # This is kinda hacky, but the boundary attr_reader may modify `self[:boundary]` in-place
    # when the source XML specifies only the start byte instead of specifying a Range.
    # The expanded `boundary` is based on the start byte plus the sequence length.
    # Due to the way Ox works, the sequence (and thus its length) may not be known
    # when the rangeless `boundary` is set, so I can't do this in the attr_writer.
    def boundary
      case
      when self[:boundary].nil?
        # This shouldn't ever happen since `offset` is a required attribute for `<match>`
        # in `shared-mime-info`, but Apache's `tika-mimetypes.xml` has a couple of types without.
        # Assume a Range of `self[:sequence]`'s length from the start of the stream.
        self[:boundary] = (0..self[:sequence].length)
      when self[:boundary]&.count == 1
        # `shared-mime-info` specifies many offsets as start-offset only, for brevity.
        # Detect these and expand our `boundary` to the full Range that will be necessary to match.
        self[:boundary] = (self[:boundary].min..self[:boundary].max + self[:sequence].length)
      else
        # Otherwise we were given a Range directly from the source XML.
        self[:boundary]
      end
    end

    extend Forwardable
    def_instance_delegators(:boundary, :min, :max, :minmax, :size, :count)
    def_instance_delegators(:sequence, :length, :bytes)

    def ==(otra)
      if self[:mask].nil? then
        return true if otra == self[:sequence]
      else
        return true if otra == self[:sequence].bytes.reduce { |int, byte| (int << 8) | byte } & self[:mask]
      end
      return false
    end

  end  # SequenceCat
end  # module CHECKING::YOU::SweetSweet♥Magic


module CHECKING::YOU::SweetSweet♡Magic
  def magic_without_tears
    @magic_without_tears ||= ::CHECKING::YOU::MagicWithoutTears.new
  end

  # TODO: Fix all the bugs in this by running a test suite.
  # It matches some file types but not some others I've tried. Gotta start somewhere though :)
  # TODO: Profile this to reduce allocations.
  WILD_IO = proc {
    # TODO: Benchmark these buffer-size assumptions
    hold_my_hand = String.new(encoding: Encoding::ASCII_8BIT, capacity: 2048)
    quick_master = String.new(encoding: Encoding::ASCII_8BIT, capacity: 2048)
    moving_on = String.new(encoding:Encoding::ASCII_8BIT, capacity: 256)
    small_clone = String.new(encoding:Encoding::ASCII_8BIT, capacity: 256)

    # Avoid re-allocating any data structure we can re-use between matches.
    the_last_striker = 0       # Previous iteration offset, used to calculate how many cached bytes to unshift.
    rolling_stops = Array.new  # Iteration end-points, to be sorted so we can pop the largest.
    rolling_stop = 0           # Iteration end-point, popped in a loop off an Array.
    my_future = Array.new      # Sub-sequence match successes and failures.
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
        #puts "Dropping #{rolling_start - the_last_striker} leading byte(s)"
        hold_my_hand.slice!(rolling_start - the_last_striker)

        # The second level of keys are byte offsets marking the ends of the areas we will inspect, e.g.:
        # irb(main):004:0> CHECKING::YOU::OUT::magic_without_tears[256].keys.sort
        # => [260, 264, 265, 268, 271]
        #
        # Again, they must be sorted to avoid insertion order.
        rolling_stops = ::CHECKING::YOU::OUT::magic_without_tears[rolling_start].keys.sort
        #puts "Reading #{rolling_stops.last - rolling_start} bytes"
        # IO#read returns `nil` if we're at the end of the stream.
        break if wild_io.read(rolling_stops.last - rolling_start, hold_my_hand).nil?

        # Empty the stops out from highest to lowest.
        while not rolling_stops.empty? do

          # Take a disposable copy of our stream cache.
          quick_master = hold_my_hand.dup

          # This is already sorted so the `last` element is the largest.
          rolling_stop = rolling_stops.pop

          # { SweetSweet♥Magic::WeightedAction => CHECKING::YOU::OUT }
          ::CHECKING::YOU::OUT::magic_without_tears[rolling_start][rolling_stop].each_pair { |weighted_action, cyo|
            #puts "Testing #{weighted_action}"

            # Each match possibility is composed of one or more sub-sequences, all of which must be matched.
            # The `boundary` Range of the full action is the sum of all `boundary` Ranges of the sub-sequences, e.g.:
            # WeightedAction[SC(5..10), SC(12..20), SC(256..512)] => WeightedAction#boundary = (5..512)
            weighted_action.each { |sequence_cat|

              # Take the sub-sequence haystack from the disposable cache.
              moving_on = quick_master.slice(sequence_cat.min - rolling_start, sequence_cat.count)
              #puts "Testing #{sequence_cat.boundary.count} bytes from offset #{sequence_cat.boundary.min - rolling_start} for #{sequence_cat}"

              # Assume we aren't a match.
              segment_matched = false

              # These haystacks may be much larger than the size of the needles, e.g. if we are looking for
              # a 4-byte sequence anywhere within the first 512 bytes of a hypothetical format.
              # If that's the case, look for a match one-needle-length at a time.
              #puts "Testing needle size #{sequence_cat.sequence.length} in #{moving_on.length}-byte haystack"
              while (moving_on.length > sequence_cat.length) do
                # We can always start from the beginning (`0`) of a haystack since any previous iteration
                # would have also sliced one-needle-length off the front.
                small_clone = moving_on.slice!(0, sequence_cat.length)

                segment_matched = true if sequence_cat == small_clone
              end
              # Always save the match status regardless if `true` or `false`.
              my_future.push(segment_matched)
            }

            # Save the sequences as well as the Type if we have a match. We need to save the sequences so we can
            # compare their `weight` in the case of multiple positives.
            #puts "Matched #{cyo} via #{weighted_action}!" if my_future.all?(true)
            come_with_me.store(weighted_action, cyo) if my_future.all?(true)
            my_future.clear

            # Save the start point so we know how many bytes to drop off the front of our stream cache.
            the_last_striker = rolling_start

          }  # self.magic_without_tears[rolling_start][rolling_stop].each_pair
        end
      }  # self.magic_without_tears.keys.sort.each
      return come_with_me.dup.tap { |out| come_with_me.clear }
    }  # find_out
    -> (wild_io) {
      return find_out.call(wild_io)
    }
  }.call

  def from_content(unknown_io)
    case unknown_io
    when IO, StringIO  # `IO` is the parent class of `File`, among others.
      # Assume for now that we should not `#close` an IO we were directly given.
      unknown_io.advise(:sequential)
      return WILD_IO.call(unknown_io)
    when String, Pathname
      # File::open takes a path, but IO::open only takes a file descriptor.
      File.open(unknown_io, mode: File::Constants::RDONLY|File::Constants::BINARY) do |wild_io|
        wild_io.advise(:sequential)
        return WILD_IO.call(wild_io)
      end
    else nil
    end
  end

end
