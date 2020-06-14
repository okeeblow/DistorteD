require 'distorted/monkey_business/hash'
require 'yaml'
require 'jekyll'


module Jekyll
  module DistorteD
    module Floor

      # Top-level config key (stringified) for Jekyll and Default YAML.
      CONFIG_KEY = :distorted

      # Filename for default config YAML. Should be a sibling of this file.
      DEFAULT_CONFIG_FILE_NAME = '_config_default.yml'

      # Separator character for pretty-printing config hierarchy.
      PP_SEPARATOR = "\u21e2 ".encode('utf-8')

      # Generic main config-loading function that will search, in order:
      # - The memoized pre-transformed config data store in-memory.
      # - Jekyll's Site config, for a passed-in site or for the default site.
      # - DistorteD's Gem-internal default config YAML.
      #
      # Config data from Jekyll or the DD Defaults is transformed to symbol-ify
      # struct keys where possible and to minimize redundant struct layers.
      def config(*keys, **kw)
        # I might forget and use a string key somewhere instead of symbols,
        # and I'd rather it be less efficient than just die. Handle that.
        config_keys = keys.compact.map{|c| symbolic(c)}
        # Initialize memoization class variable as a Hash that will return another
        # new empty Hash for any key access that doesn't already contain something.
        @@memories ||= Hash.new {|h,k| h[k] = h.class.new(&h.default_proc) }
        # Try to load a memoized config if we can, to skip any filesystem
        # access and data transformation steps.
        config = @@memories.dig(*config_keys)
        # Hash#dig usually returns nil for missing keys, but our memoization
        # Hash will also return another new empty Hash.
        unless config.empty? or config.nil?
          # Boom.
          Jekyll.logger.debug(@tag_name, "Using memoized config for key '#{config_keys.join(PP_SEPARATOR)}': #{config}")
          config
        else
          # The key isn't memoized. Look for it first in Jekyll's Site config,
          # then in the _config_default.yml file contained here in this Gem.
          # Floor#config_site also takes a `site` kwarg that will be passed along.
          new = self.config_site(*config_keys, **kw) || self.config_default(*config_keys) || {}
          @@memories.bury(*config_keys, new)
          new
        end
      end

      # This helper is used by Floor#config to load Jekyll Site config but
      # can be used directly to bypass memoization.
      def config_site(*keys, **kw)
        # Is it even possible to have more than one Site? Support being passed
        # a `site` object just in case, but taking the first one should be fine.
        site = kw[:site] || Jekyll.sites.first
        # Jekyll's YAML config will only ever give us string keys. Look for that.
        config_keys = [CONFIG_KEY].concat(keys).map(&:to_s)
        # Get the config, or nil if the queried config path doesn't exist.
        # Minimize and symbolize any output.
        site_config = symbolic(minimalian(site.config.dig(*config_keys)))
        Jekyll.logger.debug(@tag_name, "Loading Jekyll _config key '#{config_keys.join(PP_SEPARATOR)}': #{site_config}")
        site_config
      end

      # This helper is used by Floor#config to load DD Default config data
      # can be used directly to bypass memoization.
      def config_default(*keys)
        # Don't move this file or the YAML defaults without changing this.
        config_path = File.join(File.dirname(__FILE__), DEFAULT_CONFIG_FILE_NAME)
        # This will always be small enough for a one-shot read.
        default_config = YAML.load(File.read(config_path))
        # Default YAML config will only ever give us string keys. Look for that.
        config_keys = [CONFIG_KEY].concat(keys).map(&:to_s)
        # Get the config, or nil if the queried config path doesn't exist.
        # Minimize and symbolize any output.
        default_config = symbolic(minimalian(default_config.dig(*config_keys)))
        Jekyll.logger.debug(@tag_name, "Loading default config from #{config_path}: #{default_config}")
        default_config
      end

      # Transform arbitrary configuration data structure keys from
      # strings to symbols before memoization.
      # https://stackoverflow.com/a/8189435
      def symbolic(c)
        # Check message-handling responses to gauge emptiness since classes that
        # don't respond to `:empty?` might not respond to `:method_exists?` either.
        if c.nil?# or c.respond_to?(:empty?) != true
          return c
        elsif c.class.method_defined?(:transform_keys)
          # Hashes
          return c.transform_keys(&:to_sym)
        elsif c.class.method_defined?(:to_sym)
          # Plain types
          return c.to_sym
        elsif c.is_a?(Enumerable)
          # Mostly Arrays. This is after Hashes and other more-specific
          # Enumerables on purpose. Don't rearrange.
          return c.map{|r| symbolic(r)}
        end
        return c
      end

      # Minimize configuration data structures where possible.
      def minimalian(c)
        # Check message-handling responses to gauge emptiness since classes that
        # don't respond to `:empty?` might not respond to `:method_exists?` either.
        if c.nil? or c.respond_to?(:empty?) != true
          return c
        # Look for work based on capability instead of ancestry.
        elsif c.class.method_defined?(:all?) and c.class.method_defined?(:map)
          if c.class.method_defined?(:count) and c.class.method_defined?(:pop)
            # Don't allow any Arrays of single items.
            if c.count == 1
              return c.pop
            end
          end
          # Combine an Array of Hashes into a single Hash iff none of
          # those Hashes have overlapping keys.
          if c.all?{|i| i.class.method_defined?(:keys)}
            if c.map(&:keys).reduce(:&).empty?
              return c.reduce(&:merge!)
            end
          end
        end
        return c
      end

      def name(suffix = nil)
        Floor::image_name(@name, suffix)
      end

      def self.image_name(orig, suffix = nil)
        if suffix
          File.basename(orig, '.*') + '-' + suffix.to_s + File.extname(orig)
        else
          orig
        end
      end

      def basename
        File.basename(@name, '.*')
      end
    end
  end
end
