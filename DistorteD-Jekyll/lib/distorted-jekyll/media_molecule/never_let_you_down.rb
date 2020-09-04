require 'set'

require 'distorted/checking_you_out'
require 'distorted/injection_of_love'

module Jekyll
  module DistorteD
    module Molecule
      module LastResort


        LOWER_WORLD = CHECKING::YOU::IN('application/x.distorted.last-resort')

        ATTRS = Set[:alt, :title, :href, :caption]
        ATTRS_DEFAULT = {}
        ATTRS_VALUES = {}

        # This is one of the few render methods that will be defined in JekyllLand.
        define_method(CHECKING::YOU::IN('application/x.distorted.last-resort').first.distorted_method) { |*a, **k, &b|
          copy_file(*a, **k, &b)
        }

        include Cooltrainer::DistorteD::InjectionOfLove


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
