require 'set' unless defined? ::Set


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

  # The following two `proc`s handle classwide-memoization and instance-level assignment
  # for values that may be Enumerable but often refer to only a single Object.
  #
  # For example, most `Postfix`es (file extensions) will only ever belong to a single CYO Object,
  # but a handful represent possibly-multiple types, like how `.doc` can be an MSWord file or WordPad RTF.
  #
  # These assignment procs take a storage haystack, a needle to store, and a CYO receiver the needle refers to.
  # They will set `haystack[needle] => CYO` if that needle is unique, or they will convert
  # an existing `haystack[needle] => CYO` assignment to `haystack[needle] => Set[existingCYO, newCYO]`.
  #
  # This is an admittedly-annoying complexity-for-performance tradeoff with the goal of allocating
  # as few spurious objects as possible instead of explicitly initializing a Set for every needle.
  CLASS_NEEDLEMAKER = proc { |haystack, needle, receiver|
    # Create the container if this is the very first invocation.
    receiver.class.instance_variable_set(haystack, Hash.new(nil)) unless receiver.class.instance_variable_defined?(haystack)

    # Set the `haystack` Hash's `needle` key to the `receiver` if the `key` is unset, otherwise
    # to a `Set` of the existing value plus `receiver` if that value is not `receiver` already.
    receiver.class.instance_variable_get(haystack).tap { |awen|
      case awen[needle]
      when nil then awen[needle] = receiver
      when ::Set then awen[needle].add(receiver)
      when receiver.class then awen[needle] = Set[awen[needle], receiver] unless awen[needle] == receiver
      end
    }
  }
  # This is the instance-level version of the above, e.g. a CYO with one file extension (`Postfix`)
  # will assign `cyo.:@postfixes = Postfix`, and one with many Postfixes will assign
  # e.g. `cyo.:@postfixes = Set[post, fix, es, …]`.
  INSTANCE_NEEDLEMAKER = proc { |haystack, needle, receiver|
    if receiver.instance_variable_defined?(haystack) then
      receiver.instance_variable_get(haystack).add(needle)
    else
      receiver.instance_variable_set(haystack, Set[needle])
    end
  }


end  # class CHECKING::YOU
