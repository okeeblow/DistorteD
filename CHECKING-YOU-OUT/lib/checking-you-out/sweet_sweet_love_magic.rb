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

  end  # WeightedAction


  # Represent one possible chain of byte sequences for a successful content match.
  SequenceCat = ::Struct.new(:sequence, :boundary, :mask) do

    # We get the raw sequence and the sequence format attributes in separate callbacks
    # due to the way Ox works, and I can't assume deterministric callback order.
    # Use one attr_writer for the sequence, one for the format, and store the intermediate value
    # directly in `self[:sequence]` so we don't allocate outside an RValue with instance vars.
    def cat=(cat);       self[:sequence] = self[:sequence].nil? ? -cat    : self[:sequence].call(cat).b;    end
    def format=(format); self[:sequence] = self[:sequence].nil? ? format : format.call(self[:sequence]).b; end

  end  # SequenceCat


  def add_content_match(action)
    self.cat_sequence.add(action)
  end

  def cat_sequence
    @cat_sequence ||= ::Set.new
  end

end
