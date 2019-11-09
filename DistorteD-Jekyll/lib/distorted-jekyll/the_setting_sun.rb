module Jekyll
  class DistorteD < Liquid::Tag
    class Floor

      attr_reader :sources

      def initialize(config, name)
        @config_key = 'distorted'
        Jekyll.logger.debug(@config_key, "Loading config from key '#{@config_key}'")
        @dimensions = config.dig(@config_key, 'image')
        Jekyll.logger.debug(@config_key, @dimensions)
        @name = name
      end

      def sources
        Jekyll.logger.debug(@config_key, @dimensions)
        @dimensions.map { |d| {
          'name' => Jekyll::DistorteD::Floor::image_name(@name, d['tag']),
          'media' => d['media']
        }}
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
