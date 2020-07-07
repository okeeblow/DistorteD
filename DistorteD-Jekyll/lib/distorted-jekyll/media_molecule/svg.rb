require 'set'

require 'distorted/svg'
require 'distorted-jekyll/static/svg'

module Jekyll
  module DistorteD
    module Molecule
      module SVG

        # Reference these instead of reassigning them. Consistency is mandatory.
        MEDIA_TYPE = Cooltrainer::DistorteD::SVG::MEDIA_TYPE
        MIME_TYPES = Cooltrainer::DistorteD::SVG::MIME_TYPES

        ATTRS = Cooltrainer::DistorteD::SVG::ATTRS
        ATTRS_DEFAULT = Cooltrainer::DistorteD::SVG::ATTRS_DEFAULT
        ATTRS_VALUES = Cooltrainer::DistorteD::SVG::ATTRS_VALUES


        def render(context)
          super
          begin
            parse_template.render({
              'name' => @name,
              'basename' => File.basename(@name, '.*'),
              'path' => @url,
              'alt' => @alt,
              'title' => @title,
              'href' => @href,
              'caption' => @caption,
            })
          rescue Liquid::SyntaxError => l
            # TODO: Only in dev
            l.message
          end
        end

        def static_file(*args)
          Jekyll::DistorteD::Static::SVG.new(*args)
        end

      end
    end
  end
end
