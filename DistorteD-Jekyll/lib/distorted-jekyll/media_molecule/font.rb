require 'set'

require 'distorted/molecule/font'


module Jekyll
  module DistorteD
    module Molecule
      module Font

        include Cooltrainer::DistorteD::Molecule::Font

        def render_to_output_buffer(context, output)
          begin
            filez = files.keep_if{ |f|
              # Strip out all non-displayable media-types, e.g. the actual text/whatever.
              f.key?(:type) && f&.dig(:type)&.media_type == 'image'.freeze
            }.keep_if{ |f|
              # Strip out full-size images (will have `nil`) — only display thumbnail vers
              f.key?(:width) or f.key?(:height)
            }.map{ |f|
              # Stringify to make Liquid happy
              f.transform_values(&:to_s).transform_keys(&:to_s)
            }
            output << parse_template.render({
              'name' => @name,
              'path' => @relative_dest,
              'alt' => abstract(:alt),
              'title' => abstract(:title),
              'sources' => filez,
              'fallback_img' => fallback_img,
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

        # Return the filename of the most-compatible output image
        # for use as the fallback <img> tag inside our <picture>.
        def fallback_img
          best_ver = nil
          files.keep_if{|f| f.key?(:type) && f&.dig(:type)&.media_type == 'image'.freeze}.each{ |f|
            # PNG > WebP
            if f&.dig(:type)&.sub_type == 'png'.freeze || best_ver.nil?
              best_ver = f
            end
          }
          # Return the filename of the biggest matched variation,
          # otherwise use the original filename.
          best_ver&.dig(:name) || @name
        end

      end  # Font
    end  # Molecule
  end  # DistorteD
end  # Jekyll
