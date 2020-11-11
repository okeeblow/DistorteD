require 'set'

require 'distorted/molecule/pdf'


module Jekyll
  module DistorteD
    module Molecule
      module PDF

        include Cooltrainer::DistorteD::Molecule::PDF


        # Generate a Hash of our PDF Open Params based on any given to the Liquid tag
        # and any loaded from the defaults.
        # https://www.adobe.com/content/dam/acom/en/devnet/acrobat/pdfs/pdf_open_parameters.pdf
        def pdf_open_params
          PDF_OPEN_PARAMS.map{ |p|
            if ATTRIBUTES_VALUES.dig(p) == BOOLEAN_ATTR_VALUES
              # Support multiple ways people might want to express a boolean
              if Set[0, '0'.freeze, false, 'false'.freeze].include?(abstract(p))
                [p, '0'.freeze]
              elsif Set[1, '1'.freeze, true, 'true'.freeze].include?(abstract(p))
                [p, '1'.freeze]
              end
            else
              [p, abstract(p)]
            end
          }.to_h
        end

        # Generate the URL fragment version of the PDF Open Params.
        # This would be difficult / impossible to construct within Liquid
        # from the individual variables, so let's just do it out here.
        def pdf_open_params_url
            pdf_open_params.keep_if{ |p,v|
            v != nil && v != ""
          }.map{ |k,v|
            # The PDF Open Params docs specify `search` should be quoted.
            if k == :search
              "#{k}=\"#{v}\""
            else
              "#{k}=#{v}"
            end
          }.join('&')
        end

        def render_to_output_buffer(context, output)
          super
          begin
            # TODO: iOS treats our <object> like an <img>,
            # showing only the first page with transparency and stretched to the
            # size of the container element.
            # We will need something like PDF.js in an <iframe> to handle this.

            output << parse_template.render({
              'name' => @name,
              'path' => @relative_dest,
              'alt' => abstract(:alt),
              'title' => abstract(:title),
              'height' => abstract(:height),
              'width' => abstract(:width),
              'caption' => abstract(:caption),
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

      end  # PDF
    end  # Molecule
  end  # DistorteD
end  # Jekyll
