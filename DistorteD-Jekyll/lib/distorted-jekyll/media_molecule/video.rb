require 'distorted/molecule/video'
require 'distorted-jekyll/static/video'


module Jekyll
  module DistorteD
    module Molecule
      module Video


        DRIVER = Cooltrainer::DistorteD::Video
        LOWER_WORLD = DRIVER::LOWER_WORLD

        ATTRS = DRIVER::ATTRS
        ATTRS_DEFAULT = DRIVER::ATTRS_DEFAULT
        ATTRS_VALUES = DRIVER::ATTRS_VALUES

        def render_to_output_buffer(context, output)
          super
          begin
            output << parse_template.render({
              'name' => @name,
              'basename' => File.basename(@name, '.*'),
              'path' => @url,
              'caption' => abstract(:caption),
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
