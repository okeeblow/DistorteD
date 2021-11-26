require(-'pathname') unless defined?(::Pathname)

require_relative(-'../weighted_action') unless defined?(::CHECKING::YOU::OUT::WeightedAction)

module ::CHECKING::YOU::OUT::SweetSweet♥Magic
  # Represent a container for multiple matching byte sequences or tree hierarchies along with a priority value
  # to use when there are multiple matches for a given `Object`, in which case the highest `weight` wins.
  # Note: Array methods will return `Array` instead of `WeightedAction` since https://bugs.ruby-lang.org/issues/6087
  SpeedyCat = ::Class::new(::Array) do

    # Byte sequence matches can be weighted so a more-specific match can be chosen
    # from among matches for e.g. container formats.
    include(::CHECKING::YOU::OUT::WeightedAction)

    # Forward `Range`-like methods to our member Sequences.
    def min;     self.map(&:min).min; end
    def max;     self.map(&:max).max; end
    def minmax; [self.min, self.max]; end
    def size;    self.max - self.min; end
    def boundary;(self.min..self.max);end

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
end
