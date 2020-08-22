require 'set'

require 'distorted/molecule/svg'
require 'distorted-jekyll/static/svg'


module Jekyll
  module DistorteD
    module Molecule
      module SVG


        DRIVER = Cooltrainer::DistorteD::SVG
        LOWER_WORLD = DRIVER::LOWER_WORLD

        ATTRS = DRIVER::ATTRS
        ATTRS_DEFAULT = DRIVER::ATTRS_DEFAULT
        ATTRS_VALUES = DRIVER::ATTRS_VALUES


        def render_to_output_buffer(context, output)
          super
          begin
            # Liquid doesn't seem able to reference symbolic keys,
            # so convert everything to string for template.
            # Not stripping :full tags like Image because all of our
            # SVG variations will be full-res for now.
            filez = files.map{ |f|
              f.transform_values(&:to_s).transform_keys(&:to_s)
            }
            output << parse_template.render({
              'name' => @name,
              'path' => @dd_dest,
              'alt' => attr_value(:alt),
              'title' => attr_value(:title),
              'href' => attr_value(:href),
              'caption' => attr_value(:caption),
              'loading' => attr_value(:loading),
              'sources' => filez,
              'fallback_img' => @name,
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
          Jekyll::DistorteD::Static::SVG.new(*args)
        end

      end
    end
  end
end
