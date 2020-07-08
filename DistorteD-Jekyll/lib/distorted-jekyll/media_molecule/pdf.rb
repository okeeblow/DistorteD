require 'set'

require 'distorted/pdf'
require 'distorted-jekyll/static/pdf'

module Jekyll
  module DistorteD
    module Molecule
      module PDF

        # Reference these instead of reassigning them. Consistency is mandatory.
        MEDIA_TYPE = Cooltrainer::DistorteD::PDF::MEDIA_TYPE
        SUB_TYPE = Cooltrainer::DistorteD::PDF::SUB_TYPE
        MIME_TYPES = Cooltrainer::DistorteD::PDF::MIME_TYPES

        ATTRS = Cooltrainer::DistorteD::PDF::ATTRS
        ATTRS_DEFAULT = Cooltrainer::DistorteD::PDF::ATTRS_DEFAULT
        ATTRS_VALUES = Cooltrainer::DistorteD::PDF::ATTRS_VALUES


        def render_to_output_buffer(context, output)
          super
          begin
            output << parse_template.render({
              'name' => @name,
              'path' => @dd_dest,
              'alt' => attr_value(:alt),
              'title' => attr_value(:title),
              'height' => attr_value(:height),
              'width' => attr_value(:width),
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
          Jekyll::DistorteD::Static::PDF.new(*args)
        end

      end  # PDF
    end  # Molecule
  end  # DistorteD
end  # Jekyll
