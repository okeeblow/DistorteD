require 'distorted/video'
require 'distorted-jekyll/static/video'

module Jekyll
  module DistorteD
    module Molecule
      module Video

        # Reference these instead of reassigning them. Consistency is mandatory.
        MEDIA_TYPE = Cooltrainer::DistorteD::Video::MEDIA_TYPE
        MIME_TYPES = Cooltrainer::DistorteD::Video::MIME_TYPES

        ATTRS = Cooltrainer::DistorteD::Video::ATTRS
        ATTRS_DEFAULT = Cooltrainer::DistorteD::Video::ATTRS_DEFAULT
        ATTRS_VALUES = Cooltrainer::DistorteD::Video::ATTRS_VALUES

        def render_to_output_buffer(context, output)
          super
          begin
            output << parse_template.render({
              'name' => @name,
              'basename' => File.basename(@name, '.*'),
              'path' => @url,
              'alt' => @alt,
              'title' => @title,
              'href' => @href,
              'caption' => @caption,
            })
          rescue Liquid::SyntaxError => l
            unless Jekyll.env == 'production'.freeze
              output << parse_template(name: 'error_code'.freeze).render({
                'message' => l.message,
              })
            end
          end
          output
        end

        def static_file(*args)
          Jekyll::DistorteD::Static::Video.new(*args)
        end

      end
    end
  end
end
