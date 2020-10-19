require 'set'
require 'distorted/monkey_business/set'


# This Module supports Module "Piles"* in DistorteD by merging
# an arbitrarily-deep nest of attribute-definition constants
# into a single combined datastructure per constant at include-/
# extend-/prepend-time.
# [*] 'Monad' doesn't feel quite right, but http://www.geekculture.com/joyoftech/joyimages/469.gif
#
# The combined structures can be accessed in one shot and trusted as
# a source of truth, versus inspecting Module::nesting or whatever
# to iterate over the masked same-Symbol constants we'd get when
# including/extending/prepending in Ruby normally:
#   - https://ruby-doc.org/core/Module.html#method-c-nesting
#   - http://valve.github.io/blog/2013/10/26/constant-resolution-in-ruby/

# There's some general redundancy here with Bundler's const_get_safely:
# https://ruby-doc.org/stdlib/libdoc/bundler/rdoc/Bundler/SharedHelpers.html#method-i-const_get_safely
#
# …but even though I use (and enjoy using) Bundler it feels Wrong™ to me to have
# that method in stdlib and especially in Core but not as part of Module since
# 'Bundler' still feels like a third-party namespace to me v(._. )v


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::InjectionOfLove

  # These hold (possibly-runtime-generated) Sets of MIME::Types (from our loader)*
  # describing any supported input media-types (:LOWER_WORLD)
  # and any supported output media-types (:OUTER_LIMITS).
  TYPE_CONSTANTS = Set[
    :LOWER_WORLD,
    :OUTER_LIMITS,
  ]
  # These hold Hashes or Sets describing supported attributes,
  # supported attribute-values (otherwise freeform),
  # attribute defaults if any, and mappings for any of those things
  # to any aliased equivalents for normalization and localization.
  ATTRIBUTE_CONSTANTS = Set[
    :ATTRIBUTES,
    :ATTRIBUTES_DEFAULT,
    :ATTRIBUTES_VALUES,
  ]
  # 🄒  All of the above.
  DISTORTED_CONSTANTS = Set[].merge(TYPE_CONSTANTS).merge(ATTRIBUTE_CONSTANTS)

  # Name of our fully-merged-Hash's class variable.
  AFTERPARTY = :@@DistorteD


  # Activate this module when it's included.
  # We will merge DistorteD attributes to the singleton class from
  # our including context and from out including context's included_modules,
  # then we will define methods in the including context to perpetuate
  # the merging process when that context is included/extended/prepended.
  def self.included(otra)
    self::Injection_Of_Love.call(otra)
    super
  end

  # "Attribute" fragments are processed in one additional step to support
  # aliased/equivalent attribute names and values.
  # This is a quality-of-life feature to help normalize/localize attributes
  # defined in a wide range of places by multiple unrelated upstream devs.
  #
  # For example, libvips savers expect a single-character upper-case
  # `Q` argument for their 1–100 integer quality factor,
  # and my VipsSave module's `:ATTRIBUTES` additionally aliases it
  # to the more typical `quality` to provide consistent UX
  # with other attributes from VIPS and other sources.
  # https://libvips.github.io/libvips/API/current/VipsForeignSave.html#vips-jpegsave
  #
  # VIPS also provides our example of the need for attribute-value equivalents,
  # such as how it only accepts the spelling of "centre" and not "center"
  # like myself and many millions of other people will reflexively enter :)
  # https://libvips.github.io/libvips/API/current/libvips-conversion.html#VipsInteresting
  def self.so_deep(fragment)
    fragment.each_with_object(Array[]) { |(attribute, raw), to_merge|
      # Each attribute's :raw may be an object (probably a Symbol),
      # a Set (e.g. of aliases), or nil (for all values in a Set.to_hash)
      case raw
        when Set then raw.add(attribute)
        when NilClass then [attribute]
        else [attribute]
      end.each{ |equivalent|
        to_merge << [equivalent, attribute]
      }
    }.to_h
  end

  # Returns a block that will define methods in a given context
  # such that when the given context is included/extended/prepended
  # we will also merge our DD attributes into the new layer.
  Injection_Of_Love = Proc.new { |otra|
    # These are the methods that actively perform the include/extend/prepend process.
    [:append_features, :prepend_features, :extend_object].each { |m|
      otra.define_singleton_method(m) do |winter|
        # Perform the normal include/extend/prepend that will mask our constants.
        super(winter)

        # Get new values to override masked constants.
        pile = Cooltrainer::DistorteD::InjectionOfLove::trip_machine(winter)

        # Record each constant individually as well as the entire pile.
        # This doesn't currently get used, as this :class_variable_set call
        # is broken in KRI:
        #  - https://bugs.ruby-lang.org/issues/7475
        #  - https://bugs.ruby-lang.org/issues/8297
        #  - https://bugs.ruby-lang.org/issues/11022
        winter.singleton_class.class_variable_set(AFTERPARTY, pile)
        pile.each_pair{ |k, v|
          if winter.singleton_class.const_defined?(k, false)
            # Since we are setting constants in the singleton_class
            # we must remove any old ones first to avoid a warning.
            winter.singleton_class.send(:remove_const, k)
          end
          winter.singleton_class.const_set(k, v)
        }
      end
    }
    # These are the callback methods called after the above methods fire.
    # Use them to perpetuate our merge by calling the thing that calls us :)
    [:included, :prepended, :extended].each { |m|
      otra.define_singleton_method(m) do |winter|
        Cooltrainer::DistorteD::InjectionOfLove::Injection_Of_Love.call(winter)
        super(winter)
      end
    }
  }

  # Returns an instance-level copy of the complete attribute pile.
  def trip_machine
    @DistorteD ||= Cooltrainer::DistorteD::InjectionOfLove::trip_machine(self.singleton_class)
  end

  # Builds the attribute pile (e.g. suported atrs, values, defaults, etc) for any given scope.
  def self.trip_machine(scope)
      attribute_aliases = Hash[]
      alias_attributes = Hash[]
      values = Hash[]
      defaults = Hash[]

      scope&.ancestors.each { |otra|
        DISTORTED_CONSTANTS.each { |invitation|  # OUT OF CONTROL / MY WHEELS IN CONSTANT MOTION
          if otra.const_defined?(invitation)
            part = otra.const_get(invitation) rescue Hash[]

            if invitation == :ATTRIBUTES
              # Support both alias-to-attribute and attribute-to-aliases
              attribute_aliases.merge!(part) { |invitation, old, new|
                if old.nil?
                  new.nil? ? Set[invitation] : Set[new]
                elsif new.nil?
                  old
                elsif new.is_a?(Enumerable)
                  old.merge(new)
                else
                  old << new
                end
              }
              alias_attributes.merge!(Cooltrainer::DistorteD::InjectionOfLove::so_deep(part))
            elsif invitation == :ATTRIBUTES_VALUES
              # Regexes currently override Enumerables
              to_merge = {}
              part.each_pair { |attribute, values|
                if values.is_a?(Regexp)
                  to_merge.update(attribute => values)
                else
                  to_merge.update(attribute => Cooltrainer::DistorteD::InjectionOfLove::so_deep(values))
                end
              }
              values.merge!(to_merge)
            elsif invitation == :ATTRIBUTES_DEFAULT
              defaults.merge!(part)
            end

          end
        }
      }

      return {
        :ATTRIBUTE_ALIASES => attribute_aliases,
        :ALIAS_ATTRIBUTES => alias_attributes,
        :ATTRIBUTES_VALUES => values,
        :ATTRIBUTES_DEFAULT => defaults,
      }
  end

  # Returns a value for any attribute.
  # In order of priority, that means:
  #  - A user-given value (Liquid, CLI, etc) iff it passes a validity check,
  #  - the default value if the given value is not in the accepted Set,
  #  - nil for unset attributes with no default defined.
  def abstract(argument)
    # Reject any unknown arguments.
    if trip_machine.dig(:ATTRIBUTE_ALIASES)&.keys.include?(argument)
      alias_possibilities = trip_machine.dig(:ATTRIBUTE_ALIASES)&.dig(argument) || Set[]
      possibilities = user_arguments&.keys.to_set & alias_possibilities

      # How many matching user-defined attributes are there for our aliases?
      case possibilities.length
      when 0
        # None; take the default.
        trip_machine.dig(:ATTRIBUTES_DEFAULT)&.dig(argument)
      when 1
        # One; does it look valid?
        is_valid = false
        user_value = user_arguments&.dig(argument)

        # Supported values may be declared as:
        #   - A Hash of values-and-their-aliases to values.
        #   - A Regex.
        #   - nil for freeform input.
        valid_value = trip_machine.dig(:ATTRIBUTES_VALUES)&.dig(argument)
        if valid_value.is_a?(Enumerable)
          if valid_value.include?(user_value)
            is_valid = true
          end
        elsif valid_value.is_a?(Regexp)
          if valid_value.match(user_value.to_s)
            is_valid = true
          end
        end

        # Return a valid user value, a default, or nil if all else fails.
        if is_valid
          # TODO: boolean casting
          user_value
        else
          trip_machine.dig(:ATTRIBUTES_DEFAULT)&.dig(argument)
        end

      else  # case user_values.length
        # Two or more; what do??
        raise RuntimeError("Can't have multiple settings for #{argument} and its aliases.")
      end
    else
      # The programmer asked for the value of an attribute that is
      # not supported by its MediaMolecule. This is most likely a bug.
      raise RuntimeError("#{argument} is not supported for #{@name}")
    end
  end


end
