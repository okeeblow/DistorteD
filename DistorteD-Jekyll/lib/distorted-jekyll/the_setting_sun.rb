require 'yaml'
require 'jekyll'
require 'set'

require 'distorted/monkey_business/hash'
require 'distorted/checking_you_out'


module Jekyll; end
module Jekyll::DistorteD

  # Top-level config key (once stringified) for Jekyll and Default YAML.
  CONFIG_ROOT_KEY = :distorted

  # Filename for default config YAML. Should be a sibling of this file.
  # Don't move this file or the YAML defaults without changing this.
  DEFAULT_CONFIG_FILE_NAME = '_config_default.yml'.freeze
  DEFAULT_CONFIG_PATH = File.join(File.dirname(__FILE__), DEFAULT_CONFIG_FILE_NAME).freeze

  # Separator character for pretty-printing config hierarchy.
  PP_SEPARATOR = "\u2B9E ".encode('utf-8').freeze

  # Path separator is almost always '/' internally, but support
  # ALT_SEPARATOR platforms too.
  # On Lunix - Ruby 2.7:
  # irb(main):003:0> File::ALT_SEPARATOR
  # => nil
  # irb(main):004:0> File::SEPARATOR
  # => "/"
  PATH_SEPARATOR = (File::ALT_SEPARATOR || File::SEPARATOR).freeze

  # Any any attr value will get a to_sym if shorter than this
  # totally arbitrary length, or if the attr key is in the plugged
  # Molecule's set of attrs that take only a defined set of values.
  # My chosen boundary length fits all of the outer-limit tag names I use,
  # like 'medium'. It fits the longest value of Vips::Interesting too,
  # though `crop` will be symbolized based on the other condition.
  ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY = 13


  # Memoization Hash for all settings data so we don't have to reprocess it for additional lookups.
  def self.memories
    @@memories ||= Hash.new
  end

  # Memoize the complete default-config to avoid touching the filesystem more than once.
  def self.distorted_default_settings
    @@distorted_default_settings ||= YAML.load(File.read(DEFAULT_CONFIG_PATH))
  end

  # Stores a given settings path/value to our memoization Hash
  # after normalizing the values, so we can be less strict about
  # the YAML formats we accept because YAML is easy to mess up.
  def self.memories!(key_paths, sources)
    # Avoid redundant memory transformations for keys we already have.
    # NOTE: This assumes settings will never change over the execution lifetime
    # of any single DistorteD instance.
    return self.memories.dig(key_paths) if self.memories.has_key?(key_paths)
    # Shorten long path members (any with underscores) so long log lines
    # don't get misaligned easily.
    # Don't log glob paths — those containing as asterisk (*).
    log_key = key_paths.detect { |path| path.none?(:"*") }.map(&:to_s).map{ |component|
      component.include?('_'.freeze) ? component.split('_'.freeze).map(&:chr).join('_'.freeze) : component
    }.join(PP_SEPARATOR.to_s).freeze

    # Try one one source Proc at a time, looking for every settings-path within it.
    # If *any* config data is returned from a source we stop processing additional sources.
    # This is to allow for default-config overriding because otherwise if we always
    # use the default config it would be impossible to turn off any of that data.
    memory = sources.reduce(nil) { |out, source|
      key_paths.each { |key_path|
        case new = source.call(key_path)
        when [out, new].all? { |c| c&.respond_to?(:update) } then out.update(new)
        when [out, new].all? { |c| c&.respond_to?(:merge)  } then out.merge(new)
        when [out, new].all? { |c| c&.respond_to?(:concat) } then out.concat(new)
        else out = new
        end
      }
      Jekyll.logger.debug(log_key, out) unless out.nil?
      break out unless out.nil?
    }

    # Most of our settings data comes from a YAML source,
    # either Jekyll's config or our Gem's built-in defaults,
    # so we should do some normalization before memoizing.
    memory = case memory
    when Array
      # Transform Array members, then transform the Array itself to a Set to dedupe.
      memory.map{ |array_member|
        case array_member
        # Symbolize Hash keys as well as String values if it has any.
        when Hash then array_member.transform_keys!(&:to_sym).transform_values!{ |hash_value|
          case hash_value
          when String then (hash_value.length <= ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY) ? hash_value.to_sym : hash_value
          else hash_value
          end
        }
        # For sub-Arrays of our Array, Symbolize their keys
        when Array then array_member.map(&:to_sym)
        # Otherwise just pass it as it was loaded from YAML
        else array_member
        end
      }.to_set
    when Hash
      # Ruby::YAML::load will parse YAML Sets (the `?` list-like syntax)
      # as a Ruby Hash with all-nil values (the internal implementation of Set)
      # unless we give our YAML files some sugar telling it what class we want:
      # https://rhnh.net/2011/01/31/yaml-tutorial/
      #
      # I wouldn't mind maintaining the default-settings YAML file with those tags,
      # but that would make it really tedious and error-prone in the Jekyll config
      # if/when it comes time to override any defaults, so I em ignoring that capability
      # and doing my own normalization here in this method.
      memory.values.all?{|v| v.nil?} ? memory.keys.map(&:to_sym).to_set : memory.transform_keys(&:to_sym)
    else memory
    end
    # Use the `key_paths` Array[Array[String] as the Hash key directly to avoid the complexity
    # of trying to splat it and nest the keys in layers of other Hashes.
    self.memories.store(key_paths, memory)
  end

  # Generic main config-loading function that will search, in order:
  # - The memoized pre-transformed config data store in-memory.
  # - Jekyll's Site config, for a passed-in site or for the default site.
  # - DistorteD's Gem-internal default config YAML.
  #
  # Optionally provide a class to be used as a fallback for missing keys.
  def self.the_setting_sun(*keys, site: Jekyll.sites.first, **kw)
    return nil if keys.empty?

    # Normalize given keys into an Array[Array[<whatever>] given these rules:
    #
    # - If all of our given keys are Arrays, assume each Array is a separate settings-path
    #   and leave them alone, e.g. [['jekyll', 'destination']] would be passed unchanged.
    #
    # - If some of our given keys are Arrays and some are not, assume the Arrays are incomplete
    #   settings-paths (suffixes) and assume the non-Arrays are prefixes that should be applied
    #   to each suffix, e.g.
    #   ['changes', ['image', '*'], ['image', 'jpeg']] becomes [['changes', 'image', 'jpeg'], ['changes', 'image', '*']]
    #
    # - If none of our given keys are an Array, assume the given keys make up
    #   a single settings-path and wrap them in an Array, e.g.:
    #   ['jekyll', 'destination'] becomes [['jekyll', 'destination']]
    key_paths = case
      when keys.all?(Array) then keys
      when keys.any?(Array) then
        keys.map.partition(&Array.method(:===)).yield_self.with_object(Array.new) { |(suffixes, prefix), combined_paths|
          suffixes.each{ |suffix| combined_paths.push(suffix.unshift(*prefix)) }
        }
      when keys.none?(Array) then Array[keys]
    end.map { |key_path|
      # Now inspect the first key of each combined path and transform accordingly:
      # - Opposite Day — :jekyll-prefixed paths get the prefix removed
      #   because that key level doesn't exist in the Jekyll config.
      # - If it already has out prefix, leave it alone.
      # - Everything else gets our :distorted prefix added if missing
      #   so I don't have to refer to the constant externally.
      # Finally, Symbolize errething for Hash key consistency in memoization
      # even though some config getters will map them back to Strings.
      case key_path.first.to_sym
      when :jekyll, :Jekyll then key_path.drop(1)
      when CONFIG_ROOT_KEY then key_path.map(&:to_sym)
      else key_path.unshift(CONFIG_ROOT_KEY).map(&:to_sym)
      end
    }

    # Do The Thing
    return memories!(key_paths, Array[
      ->(key_path){ site.config.dig(*key_path.map(&:to_s))},
      ->(key_path){ self::distorted_default_settings.dig(*key_path.map(&:to_s))},
    ])
  end  # self.the_setting_sun
end  # module Jekyll::DistorteD


module Jekyll::DistorteD::Setting
  # Instance version of Setting entry-point.
  def the_setting_sun(*a, **k, &b); Jekyll::DistorteD::the_setting_sun(*a, **k, &b); end
end
