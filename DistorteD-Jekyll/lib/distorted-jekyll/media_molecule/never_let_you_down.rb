require 'set'

require 'distorted-jekyll/static/lastresort'

module Jekyll
  module DistorteD
    module Molecule
      module LastResort


        LOWER_WORLD = CHECKING::YOU::IN('application/x.distorted.last-resort')

        ATTRS = Jekyll::DistorteD::Static::LastResort::ATTRS
        ATTRS_DEFAULT = {}
        ATTRS_VALUES = {}

        def render_to_output_buffer(context, output)
          super
          begin
            output << parse_template.render({
              'name' => @name,
              'basename' => File.basename(@name, '.*'),
              'path' => @dd_dest,
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
