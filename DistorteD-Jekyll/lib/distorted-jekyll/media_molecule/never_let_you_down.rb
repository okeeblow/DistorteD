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

        ATTRS = Set[]
        ATTRS_DEFAULT = {}
        ATTRS_VALUES = {}

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
          Jekyll::DistorteD::Static::LastResort.new(*args)
        end
      end
    end
  end
end
