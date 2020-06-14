require 'distorted-jekyll/static/image'

module Jekyll
  module DistorteD
    module Image

      MEDIA_TYPE = Cooltrainer::DistorteD::Image::MEDIA_TYPE
      MIME_TYPES = Cooltrainer::DistorteD::Image::MIME_TYPES
      ATTRS = Set[:alt, :caption, :href, :crop]
      CONFIG_SUBKEY = :image

      # This will become render_to_output_buffer(context, output) some day,
      # according to upstream Liquid tag.rb.
      def render(context)
        super
        begin
          parse_template.render({
            'name' => @name,
            'path' => @url,
            'alt' => @alt,
            'title' => @title,
            'href' => @href,
            'caption' => @caption,
            'sources' => sources,
          })
        rescue Liquid::SyntaxError => l
          # TODO: Only in dev
          l.message
        end
      end

      def dimensions
        config(CONFIG_SUBKEY)
      end

      def sources
        dimensions.map { |d| {
          'name' => name(d[:tag]),
          'media' => d[:media]
        }}
      end

      def static_file(site, base, dir, name, url)
        Jekyll::DistorteD::ImageFile.new(site, base, dir, name, url)
      end

    end
  end
end
