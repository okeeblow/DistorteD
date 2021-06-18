# Find-by-content file matching à la `libmagic`.
# https://www.freebsd.org/cgi/man.cgi?query=magic&sektion=5


module CHECKING::YOU::SweetSweet♥Magic


  # Represent a container for multiple matching byte sequences along with a priority value
  # to use when there are multiple matches for a stream, in which case the highest `weight` wins.
  # Note: Array methods will return `Array` instead of `WeightedAction` since https://bugs.ruby-lang.org/issues/6087
  class WeightedAction < ::Array

    # In `shared-mime-info`, "The default priority value is 50, and the maximum is 100."
    attr_accessor :weight
    def new(weight: 50); @weight = weight; super;                        end
    def clear;           @weight = 50;     super;                        end
    def inspect;         "#<#{self.class.name} #{weight} #{self.to_s}>"; end

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

  end  # SequenceCat


  def add_content_match(action)
    self.cat_sequence.add(action)
  end

  def cat_sequence
    @cat_sequence ||= ::Set.new
  end

end
