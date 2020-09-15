require 'set'
require 'distorted/monkey_business/set'


# There's some general redundancy here with Bundler's const_get_safely:
# https://ruby-doc.org/stdlib/libdoc/bundler/rdoc/Bundler/SharedHelpers.html#method-i-const_get_safely
#
# …but even though I use and enjoy using Bundler it feels Wrong™ to me to have
# that method in stdlib and especially in Core but not as part of Module since
# 'Bundler' still feels like a third-party namespace to me v(._. )v


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::InjectionOfLove


  # Only touch certain attributes so we aren't entirely rude.
  DISTORTED_CONSTANTS = Set[
    :LOWER_WORLD,
    :OUTER_LIMITS,
    :ATTRS,
    :ATTRS_DEFAULT,
    :ATTRS_VALUES,
  ]

  # Returns a block that performs the DistorteD attribute constant merge.
  # for attributes defined in our including scope /!\ *prior* to our inclusion /!\.
  MrConstant = Proc.new { |from, to, inherit: false|
    # Load the base Hash from an existing instance variable iff one is set.
    out = from.instance_variable_get(:@DistorteD) || Hash[]

    DISTORTED_CONSTANTS.each { |invitation|
      merged = out.dig(invitation)
      # Merge the included context, the includ_ing_ context, and any contexts
      # already included in the including context.
      [from, to].concat(to.included_modules).each { |m|
        # Search constant set on the Object, on the Class, and on the singleton class.
        [m, m.class, m.singleton_class].each { |c|
          if c.const_defined?(invitation, false)
            if merged.nil?
              # We support multiple data structures (e.g. Set and Hash),
              # so we won't know what type to instantiate until we've
              # seen each constant for the first time.
              merged = c.const_get(invitation).dup
            else
              # If we've already seen one instance of a certain constant
              # we should instead merge the old contents with the new.
              old = c.const_get(invitation)
              unless old.nil?
                merged.merge(old)
              end
            end
          end
        }
      }
      out[invitation] = merged
    }
    # return (without using the `return` keyword in a Block lol)
    # the complete merged output.
    out
  }

  # Returns a block that will define methods in a given context
  # such that when the given context is included/extended/prepended
  # we will first merge our DD attributes into the new layer,
  # then calling :super on the new layer to resume the
  # include/extend/prepend process (/!\ important /!\ lol).
  # The entire stack of attributes would still be accessible in
  # any layer by chaining :super there, but I want to merge them.
  Invitation = Proc.new { |otra|
    # These are the methods that actively perform the include/extend/prepend process.
    [:append_features, :prepend_features, :extend_object].each { |m|
      otra.define_singleton_method(m) do |winter|
        # Get the merged attribute Hash
        merged = Cooltrainer::DistorteD::InjectionOfLove::MrConstant.call(otra, winter)
        # Perform the normal include/extend/prepend that will mask our constants.
        super(winter)
        # Assign each merged constant to the new context.
        merged.each_pair{ |k, v|
          # Since we are setting constants in the singleton_class
          # we must remove any old ones first to avoid a warning.
          if winter.singleton_class.const_defined?(k, false)
            winter.singleton_class.send(:remove_const, k)
          end
          winter.singleton_class.const_set(k, v)
        }
        # Also save the complete Hash to an instance variable
        winter.instance_variable_set(:@DistorteD, merged)
      end
    }
    # These are the callback methods called after the above methods fire.
    # Use them to perpetuate our merge by calling the thing that calls us :)
    [:included, :prepended, :extended].each { |m|
      otra.define_singleton_method(m) do |winter|
        Cooltrainer::DistorteD::InjectionOfLove::Invitation.call(winter)
        super(winter)
      end
    }
  }

  # Activate this module when it's included.
  # We will merge DistorteD attributes to the singleton class from
  # our including context and from out including context's included_modules,
  # then we will define methods in the including context to perpetuate
  # the merging process when that context is included/extended/prepended.
  def self.included(otra)
    self::Invitation.call(otra)
    super
  end

end
