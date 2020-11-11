require 'set'

require 'distorted/molecule/svg'


module Jekyll
  module DistorteD
    module Molecule
      module SVG

        include Cooltrainer::DistorteD::Molecule::SVG

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
              'path' => @relative_dest,
              'alt' => abstract(:alt),
              'title' => abstract(:title),
              'href' => abstract(:href),
              'caption' => abstract(:caption),
              'loading' => abstract(:loading),
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

      end
    end
  end
end
