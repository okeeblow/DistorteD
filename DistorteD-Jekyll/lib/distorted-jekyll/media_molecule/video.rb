require 'distorted-jekyll/static/video'

module Jekyll
  module DistorteD
    module Video
    module Molecule
      module Video
        include Jekyll::DistorteD::Molecule::C18H27NO3;

      MEDIA_TYPE = Cooltrainer::DistorteD::Video::MEDIA_TYPE
      MIME_TYPES = Cooltrainer::DistorteD::Video::MIME_TYPES
      ATTRS = Set[:caption]
      CONFIG_SUBKEY = :video

      # This will become render_to_output_buffer(context, output) some day,
      # according to upstream Liquid tag.rb.
      def render(context)
        super
        begin
          parse_template.render({
            'name' => @name,
            'basename' => @basename,
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

      def sources
        config(:video).map { |d| {
          'name' => name(d['tag']),
          'media' => d['media']
        }}
      end

      def static_file(site, base, dir, name, url)
        Jekyll::DistorteD::VideoFile.new(site, base, dir, name, url)
      end

    end
  end
end
