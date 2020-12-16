require 'yaml'
require 'jekyll'
require 'set'

require 'distorted/monkey_business/hash'
require 'distorted/checking_you_out'


module Jekyll
  module DistorteD
    module Setting


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


      # Stores a given settings path/value to our memoization Hash
      # after normalizing the values, so we can be less strict about
      # the YAML formats we accept because YAML is easy to mess up.
      def memories!(key_path, memory)
        # Nothing to do if we got a nil value.
        return nil if memory.nil?

        # Avoid redundant memory transformations for keys we already have.
        # NOTE: This assumes settings will never change over the execution lifetime
        # of any single DistorteD instance.
        return memories.dig(key_path) if memories.has_key?(key_path)

        # Most of our settings data comes from a YAML source,
        # either Jekyll's config or our Gem's built-in defaults,
        # so we should do some normalization before memoizing.
        memory = case memory
        when Array
          # Transform Array members, then transform the Array itself to a Set to dedupe.
          memory.map{ |o|
            case o
            # Symbolize Hash keys as well as its String values if it has any.
            when Hash then o.transform_keys!(&:to_sym).transform_values!{ |v|
              case v
              when String then (v.length <= ARBITRARY_ATTR_SYMBOL_STRING_LENGTH_BOUNDARY) ? v.to_sym : v
              else v
              end
            }
            when Array then o.map(&:to_sym)
            else o
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
        # Use the `key_path` Array as the Hash key directly to avoid the complexity
        # of trying to splat it and nest the keys in layers of other Hashes.
        memories.store(key_path, memory)
      end

      def memories
        @@memories ||= Hash.new
      end

      def distorted_default_settings
        @@distorted_default_settings ||= YAML.load(File.read(DEFAULT_CONFIG_PATH))
      end

      # Generic main config-loading function that will search, in order:
      # - The memoized pre-transformed config data store in-memory.
      # - Jekyll's Site config, for a passed-in site or for the default site.
      # - DistorteD's Gem-internal default config YAML.
      #
      # Optionally provide a class to be used as a fallback for missing keys.
      def the_setting_sun(*keys, site: Jekyll.sites.first, **kw)
        return nil if keys.empty?

        # Opposite Day — :jekyll-prefixed paths get the prefix removed,
        # and everything else gets our prefix added if missing,
        # so I don't have to refer to the constant externally.
        key_path = case keys.first.to_sym
        when :jekyll, :Jekyll then keys.drop(1).map(&:to_sym)
        when CONFIG_ROOT_KEY then keys.map(&:to_sym)
        else keys.unshift(CONFIG_ROOT_KEY).map(&:to_sym)
        end

        # Shorten long path members (any with underscores) so long log lines
        # don't get misaligned easily.
        log_key = key_path.map(&:to_s).map{|c|
          c.include?('_'.freeze) ? c.split('_'.freeze).map{|p| p[0]}.join('_'.freeze) : c
        }.join(PP_SEPARATOR.to_s).freeze

        # Do The Thing
        return memories!(key_path, Array[
          ->(key_path){ memories.dig(key_path)},
          ->(key_path){ Jekyll.sites.first.config.dig(*key_path.map(&:to_s))},
          ->(key_path){ distorted_default_settings.dig(*key_path.map(&:to_s))},
        ].reduce(nil) { |out, source|
          out = source.call(key_path)
          Jekyll.logger.debug(log_key, out) unless out.nil?
          break out unless out.nil?
        })

      end

    end
  end
end
