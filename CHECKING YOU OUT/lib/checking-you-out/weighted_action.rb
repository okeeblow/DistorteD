# Several of our utility classes are like built-in-Ruby-type-plus-weight-for-comparison.
# Importing this Module enables that behavior.
module ::CHECKING::YOU::OUT::WeightedAction

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
  include(::Comparable)
  def <=>(otra); self.weight <=> otra.weight; end

end  # module WeightedAction
