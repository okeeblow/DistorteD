require 'set'

require 'distorted-jekyll/static/lastresort'

module Jekyll
  module DistorteD
    module Molecule
      module LastResort

        MEDIA_TYPE = 'lastresort'.freeze

        # HACK HACK HACK
        # Image Maps are a '90s Web relic, but I'm using this
        # MIME::Type here to represent the generic fallback state.
        # The MIME::Types library doesn't let me register custom
        # types without shipping an entire custom type database,
        # so I'm just going to use this since it will never
        # be detected for a real file, and if it does then it will
        # get an <img> tag anyway :)
        MIME_TYPES = MIME::Types['application/x-imagemap'].to_set

        ATTRS = Set[:alt, :title, :href, :caption]
        ATTRS_DEFAULT = {}
        ATTRS_VALUES = {}

        def render_to_output_buffer(context, output)
          super
          begin
            output << parse_template.render({
              'name' => @name,
              'basename' => File.basename(@name, '.*'),
              'path' => @url,
              'alt' => attr_value(:alt),
              'title' => attr_value(:title),
              'href' => attr_value(:href),
              'caption' => attr_value(:caption),
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
          Jekyll::DistorteD::Static::LastResort.new(*args)
        end
      end
    end
  end
end
