# This file defines various utility Modules/procs/etc that should be available
# to all other CYO components without `including`.
# This lets be declutter the other Modules and also serves the practical purpose
# of letting me silence `Warning`s like the one for using Ruby 2.7's pattern matching syntax.
# Defining `Warning[:experimental] = false` does not silence Warnings further in to the same file,
# so affected procs have to exist at least one level past CYO's library entry point file.
class CHECKING::YOU

  # Several of our needed utility classes are like built-in-Ruby-type-plus-weight-for-comparison.
  # I know it's widely frowned upon to subclass core types, but I'm going to do it here anyway
  # in the interest of minimizing Object allocations since many of them can get away with
  # not setting a `@weight` IVar at all.
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

end  # class CHECKING::YOU
