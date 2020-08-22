require 'set'

require 'distorted/molecule/pdf'
require 'distorted-jekyll/static/pdf'


module Jekyll
  module DistorteD
    module Molecule
      module PDF


        DRIVER = Cooltrainer::DistorteD::PDF
        LOWER_WORLD = DRIVER::LOWER_WORLD

        PDF_OPEN_PARAMS = DRIVER::PDF_OPEN_PARAMS
        ATTRS = DRIVER::ATTRS
        ATTRS_DEFAULT = DRIVER::ATTRS_DEFAULT
        ATTRS_VALUES = DRIVER::ATTRS_VALUES


        def render_to_output_buffer(context, output)
          super
          begin
            # TODO: iOS treats our <object> like an <img>,
            # showing only the first page with transparency and stretched to the
            # size of the container element.
            # We will need something like PDF.js in an <iframe> to handle this.

            # Generate a Hash of our PDF Open Params based on any given to the Liquid tag
            # and any loaded from the defaults.
            # https://www.adobe.com/content/dam/acom/en/devnet/acrobat/pdfs/pdf_open_parameters.pdf
            pdf_open_params = PDF_OPEN_PARAMS.map{ |p|
              if ATTRS_VALUES.dig(p) == DRIVER::BOOLEAN_SET
                # Support multiple ways people might want to express a boolean
                if Set[0, '0'.freeze, false, 'false'.freeze].include?(attr_value(p))
                  [p, '0'.freeze]
                elsif Set[1, '1'.freeze, true, 'true'.freeze].include?(attr_value(p))
                  [p, '1'.freeze]
                end
              else
                [p, attr_value(p)]
              end
            }.to_h

            # Generate the URL fragment version of the PDF Open Params.
            # This would be difficult / impossible to construct within Liquid
            # from the individual variables, so let's just do it out here.
            pdf_open_params_url = pdf_open_params.keep_if{ |p,v|
              v != nil && v != ""
            }.map{ |k,v|
              # The PDF Open Params docs specify `search` should be quoted.
              if k == :search
                "#{k}=\"#{v}\""
              else
                "#{k}=#{v}"
              end
            }.join('&')
            Jekyll.logger.debug("#{@name} PDF Open Params:", "#{pdf_open_params} #{"\u21e8".encode('utf-8').freeze} #{pdf_open_params_url}")

            output << parse_template.render({
              'name' => @name,
              'path' => @dd_dest,
              'alt' => attr_value(:alt),
              'title' => attr_value(:title),
              'height' => attr_value(:height),
              'width' => attr_value(:width),
              'caption' => attr_value(:caption),
              'pdf_open_params' => pdf_open_params_url,
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
