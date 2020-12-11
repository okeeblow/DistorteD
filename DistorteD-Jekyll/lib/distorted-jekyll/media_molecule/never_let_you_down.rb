require 'set'

require 'distorted/checking_you_out'

module Jekyll
  module DistorteD
    module Molecule
      module LastResort


        LOWER_WORLD = CHECKING::YOU::IN('application/x.distorted.last-resort').to_hash.transform_values{ |v| Hash[
          :alt => Cooltrainer::Compound.new(:alt, blurb: 'Alternate text to display when this element cannot be rendered.'),
          :title => Cooltrainer::Compound.new(:title, blurb: 'Extra information about this element — usually displayed as tooltip text.'),
          :href => Cooltrainer::Compound.new(:href, blurb: 'Hyperlink reference for this element.')
        ]}

        # This is one of the few render methods that will be defined in JekyllLand.
        define_method(CHECKING::YOU::IN('application/x.distorted.last-resort').first.distorted_method) { |*a, **k, &b|
          copy_file(*a, **k, &b)
        }


        def render_to_output_buffer(context, output)
          super
          begin
            output << parse_template.render({
              'name' => @name,
              'basename' => File.basename(@name, '.*'),
              'path' => @relative_dest,
              'alt' => abstract(:alt),
              'title' => abstract(:title),
              'href' => abstract(:href),
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

      end
    end
  end
end
