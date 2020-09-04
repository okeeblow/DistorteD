require 'distorted/monkey_business/hash'
require 'yaml'
require 'jekyll'
require 'set'


module Jekyll
  module DistorteD
    class Floor

      # Top-level config key (once stringified) for Jekyll and Default YAML.
      CONFIG_ROOT = :distorted

      # Filename for default config YAML. Should be a sibling of this file.
      # Don't move this file or the YAML defaults without changing this.
      DEFAULT_CONFIG_FILE_NAME = '_config_default.yml'.freeze
      DEFAULT_CONFIG_PATH = File.join(File.dirname(__FILE__), DEFAULT_CONFIG_FILE_NAME).freeze

      # Separator character for pretty-printing config hierarchy.
      PP_SEPARATOR = "\u21e2 ".encode('utf-8').freeze

      # Path separator is almost always '/' internally, but support
      # ALT_SEPARATOR platforms too.
      # On Lunix - Ruby 2.7:
      # irb(main):003:0> File::ALT_SEPARATOR
      # => nil
      # irb(main):004:0> File::SEPARATOR
      # => "/"
      PATH_SEPARATOR = (File::ALT_SEPARATOR || File::SEPARATOR).freeze


      # Generic main config-loading function that will search, in order:
      # - The memoized pre-transformed config data store in-memory.
      # - Jekyll's Site config, for a passed-in site or for the default site.
      # - DistorteD's Gem-internal default config YAML.
      #
      # Optionally provide a class to be used as a fallback for missing keys.
      def self.config(*keys, **kw)
        # Symbolize for our internal representation of the config path.
        # The Jekyll config and default config are both YAML, so we want string
        # keys for them. Go ahead and prepend the top-level search key here too.
        memo_keys = keys.compact.map(&:to_sym).to_set
        search_keys = keys.compact.map(&:to_s).map(&:freeze)
        # Pretty print the config path for logging.
        log_key = search_keys.join(PP_SEPARATOR.to_s).freeze
        # Initialize memoization class variable as a Hash that will return nil
        # for any key access that doesn't already contain something.
        @@memories ||= Hash.new { |h,k| h[k] = h.class.new(&h.default_proc) }
        # Try to load a memoized config if we can, to skip any filesystem
        # access and data transformation steps.
        config = @@memories&.dig(*memo_keys)
        unless config.nil?
          if config.is_a?(TrueClass) || config.is_a?(FalseClass)
            return config
          elsif config.is_a?(Enumerable)
            unless config.empty?
              # Can't check this at the top level because True/FalseClass
              # don't respond to this message.
              return config
            end
          end
        end

        # The key isn't memoized. Look for it first in Jekyll's Site config.
        # Is it even possible to have more than one Site? Support being passed
        # a `site` object just in case, but taking the first one should be fine.
        site = kw[:site] || Jekyll.sites.first
        # Get the config, or nil if the queried config path doesn't exist.
        loaded_config = site.config.dig(*search_keys)
        if loaded_config.nil?
          # The wanted config key didn't exist in the Site config, so let's
          # try our defaults!
          # This file will always be small enough for a one-shot read.
          default_config = YAML.load(File.read(DEFAULT_CONFIG_PATH))
          loaded_config = default_config.dig(*search_keys)
          unless loaded_config.nil?
            Jekyll.logger.debug(['Default', log_key].join(PP_SEPARATOR.to_s).concat(':'.freeze), loaded_config)
          end
        else  # else Jekyll _config is not nil
          Jekyll.logger.debug(['_config', log_key].join(PP_SEPARATOR.to_s).concat(':'.freeze), loaded_config)
        end
        # Was the desired config key found in the Gem defaults?
        if loaded_config.nil?
          # Nope.
          return nil
        else
          # Symbolize any output keys and values, and convert Arrays and Ruby::YAML
          # Sets-as-Hashes to Ruby stdlib Sets.
          # Returning a Set instead of an Array should be fine since none of our
          # configs can (read: should) contain duplicate values for any reason.
          loaded_config = symbolic(set_me_free(loaded_config))
        end
        # Memoize any of our own config, but just return anything outside our tree.
        if keys.first == CONFIG_ROOT
          @@memories.bury(*memo_keys, loaded_config)
          Jekyll.logger.debug(log_key, "Memoizing config: #{@@memories.dig(*memo_keys)}")
          # And return a config to the caller. Don't return the `new`ly fetched
          # data directly to ensure consistency between this first fetch and
          # subsequent memoized fetches, and to let callers take advantage of
          # the memo Hash's `default_proc` setup.
          return @@memories.dig(*memo_keys)
        else
          return loaded_config
        end
      end

      # AFAICT Ruby::YAML will not give me a Ruby Set[] for a YAML Set,
      # just a Hash with all-nil-values which is what it is internally.
      # distorted⇢ image Trying Jekyll _config key: {"(max-width: 400px)"=>nil, "(min-width: 800px)"=>nil, "(min-width: 1500px)"=>nil}
      # It is possible with some sugar in the YAML files, but I don't
      # want to ask anyone to do that :)
      # https://rhnh.net/2011/01/31/yaml-tutorial/
      def self.set_me_free(dunno)
        if dunno.class == Array
          return dunno&.to_set.map{|d| set_me_free(d)}
        elsif dunno.class == Hash
          if dunno&.values.all?{|v| v.nil?}
            return dunno&.keys.to_set
          else
            return dunno&.transform_values!{|v| set_me_free(v)}
          end
        end
        return dunno
      end

      # Transform arbitrary configuration data structure keys from
      # strings to symbols before memoization.
      # https://stackoverflow.com/a/8189435
      def self.symbolic(dunno)
        # Check message-handling responses to gauge emptiness since classes that
        # don't respond to `:empty?` might not respond to `:method_exists?` either.
        if dunno.nil?
          return dunno
        elsif dunno.class == Hash
          return dunno.transform_keys!(&:to_sym).transform_values!{|v| symbolic(v)}
        elsif dunno.class == Array
          return dunno.map{|r| symbolic(r)}
        elsif dunno.respond_to?(:to_sym)
          # Plain types
          return dunno.to_sym
        elsif dunno.respond_to?(:to_str)
          # Freeze string config values.
          # Specifically :to_str, not :to_s. Usually implemented by actual Strings.
          return dunno.to_str.freeze
        end
        return dunno
      end

    end
  end
end
