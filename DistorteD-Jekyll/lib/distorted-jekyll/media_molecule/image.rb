require 'set'

require 'distorted/image'
require 'distorted-jekyll/static/image'

module Jekyll
  module DistorteD
    module Molecule
      module Image

        # Reference these instead of reassigning them. Consistency is mandatory.
        MEDIA_TYPE = Cooltrainer::DistorteD::Image::MEDIA_TYPE
        MIME_TYPES = Cooltrainer::DistorteD::Image::MIME_TYPES

        ATTRS = Cooltrainer::DistorteD::Image::ATTRS
        ATTRS_DEFAULT = Cooltrainer::DistorteD::Image::ATTRS_DEFAULT
        ATTRS_VALUES = Cooltrainer::DistorteD::Image::ATTRS_VALUES


        # Returns the filename we should use in the oldschool <img> tag
        # as a fallback for <picture> sources. This file should be a cropped
        # variation, the same MIME::Type as the input media, with the largest
        # resolution possible.
        # Failing that, use the filename of the original media.
        # TODO: Handle situations when the input media_type is not in the
        # Set of output media_types. We should pick the largest cropped variation
        # of any type in that case.
        def fallback_img
          biggest_ver = nil

          # Computes a Set of non-nil MIME::Type.sub_types for all MIME::Types
          # detected for the original media file.
          sub_types = @mime.keep_if{ |m|
            m.media_type == self.singleton_class.const_get(:MEDIA_TYPE)
          }.map { |m|
            m.sub_type
          }.compact.to_set
          files.keep_if{|f| f.key?(:width) or f.key?(:height)}.each{ |f|
            if sub_types.include?(f[:type]&.sub_type)
              if biggest_ver
                if f[:width] > biggest_ver[:width]
                  biggest_ver = f
                end
              else
                biggest_ver = f
              end
            end
          }
          # Return the filename of the biggest matched variation,
          # otherwise use the original filename.
          biggest_ver&.dig(:name) || @name
        end

        def render_to_output_buffer(context, output)
          super
          begin
            # Liquid doesn't seem able to reference symbolic keys,
            # so convert everything to string for template.
            # Remove full-size images from <sources> list before generating.
            # Those should only be linked to, not displayed.
            filez = files.keep_if{|f| f.key?(:width) or f.key?(:height)}.map{ |f|
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

        def static_file(*args)
          Jekyll::DistorteD::Static::Image.new(*args)
        end

      end
    end
  end
end
