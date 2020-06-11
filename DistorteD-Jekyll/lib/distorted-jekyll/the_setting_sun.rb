require 'yaml'
require 'jekyll'

module Jekyll
  module DistorteD
    module Floor

      CONFIG_KEY = 'distorted'
      DEFAULT_CONFIG_FILE_NAME = '_config_default.yml'

      def config(media_type, site = nil)
        # Memoize media_type config to avoid multiple YAML file loads
        @@config ||= Hash.new { |hash, media_type| hash[media_type] = {} }
        @@config[media_type] ||= self.config_site(media_type, site=site) || self.config_default(media_type) || {}
      end

      def config_site(media_type, site = nil)
        site = site || Jekyll.sites.first
        Jekyll.logger.debug(CONFIG_KEY, "Loading config from key '#{CONFIG_KEY}'")
        site.config.dig(CONFIG_KEY, media_type.to_s)
      end

      def config_default(media_type)
        config_path = File.join(File.dirname(__FILE__), DEFAULT_CONFIG_FILE_NAME)
        Jekyll.logger.debug(@tag_name, "Loading default config from #{config_path}")
        default_config = YAML.load(File.read(config_path))
        default_config.dig(CONFIG_KEY, media_type.to_s)
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
    end
  end
end
