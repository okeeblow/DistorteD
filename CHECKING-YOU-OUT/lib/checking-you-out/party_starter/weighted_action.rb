class CHECKING::YOU

  # Several of our utility classes are like built-in-Ruby-type-plus-weight-for-comparison.
  # Importing this Module enables that behavior.
  module WeightedAction
    # In `shared-mime-info`, "The default priority value is 50, and the maximum is 100."
    DEFAULT_WEIGHT       = 50

    def initialize(*args, weight: nil, **kwargs)
      # Don't allocate an IVar if we're just going to use the default value.
      instance_variable_set(:@weight, weight) unless weight.nil? or weight == DEFAULT_WEIGHT
      super(*args, **kwargs)
    end
    def weight;          @weight || DEFAULT_WEIGHT;                                                              end
    def weight=(weight); instance_variable_set(:@weight, weight) unless weight.nil? or weight == DEFAULT_WEIGHT; end
    def clear;           remove_instance_variable(:@weight) if instance_variable_defined?(:@weight); super;      end
    def inspect;         "#<#{self.class.name} #{weight} #{self.to_s}>";                                         end

    # Support sorting WeightedActions against each other.
    # It seems like we have to actually implement :<=> for `Comparable`; at least I couldn't get it working
    # with `Forwardable`'s `def_instance_delegator(:weight, :<=>)`.            v(._. )v
    include Comparable
    def <=>(otra); self.weight <=> otra.weight; end
  end  # module WeightedAction

  # Extract the heaviest member(s) from an Enumerable of weighted keys.
  LEGENDARY_HEAVY_GLOW = ->(weights, *actions) {
    # Support multiple filter messages for a single Enumerable.
    push_up = proc { |action, weights|
      weights.select!.with_object(
        (weights.is_a?(::Hash) ? weights.keys : weights).max.send(action)
      ) { |(weight, _), max| weight.send(action) >= max }
      weights
    }
    (weights.nil? or weights&.empty?) ? nil
      : actions.each_with_object(weights).map(&push_up).is_a?(::Hash) ?
        (weights.values.one?) ? weights.values.first : weights.values
        : weights
  }

end
