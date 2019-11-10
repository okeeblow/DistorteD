module Jekyll
  module DistorteD
    module Floor

      CONFIG_KEY = 'distorted'

      def config(site, media_type)
        Jekyll.logger.debug(CONFIG_KEY, "Loading config from key '#{CONFIG_KEY}'")
        site.config.dig(CONFIG_KEY, media_type.to_s)
      end

      def name(suffix = nil)
        Floor::image_name(@name, suffix)
      end

      def self.image_name(orig, suffix = nil)
        if suffix
          File.basename(orig, '.*') + '-' + suffix + File.extname(orig)
        else
          orig
        end
      end
    end
  end
end
