
# Slip in and out of phenomenon
require 'liquid/tag'
require 'liquid/tag/parser'

# Explicitly required for l/t/parser since a1cfa27c27cf4d4c308da2f75fbae88e9d5ae893
require 'shellwords'


module Jekyll
  module DistorteD
    class ThirteenthStyle < Liquid::Tag

      TAB_SEQUENCE = '  '.freeze  # two spaces

      def initialize(tag_name, arguments, liquid_options)
        super

        # Liquid leaves argument parsing totally up to us.
        # Use the envygeeks/liquid-tag-parser library to wrangle them.
        parsed_arguments = Liquid::Tag::Parser.new(arguments)

        # Specify how many levels to indent printed output.
        # Indentation will apply to all lines after the first,
        # because the first line's output will fall at the same
        # place as our Liquid tag invocation.
        @tabs = parsed_arguments[:tabs] || 0
      end

      # This is going to go away in a future Liquid version
      # and render_to_output_buffer will be the standard approach.
      # I'm going ahead and using it since we are building strings here.
      def render(context)
        return render_to_output_buffer(context, '')
      end

      def render_to_output_buffer(context, output)
        css_filename = File.join(File.dirname(__FILE__), 'template'.freeze, '13th-style.css'.freeze)

        # Use IO.foreach() to call a block on each line of our template file
        # without slurping the entire file into memory like File.read() / File.readlines()
        File.foreach(css_filename).with_index do |line, line_num|
          # Don't indent the first line of the CSS file, because the first line
          # will print starting at the position of our {% 13thStyle %} Liquid tag.
          unless line_num == 0
            output << TAB_SEQUENCE * @tabs
          end
          output << line
        end
        return output
      end

    end  # ThirteenthStyle
  end  # DistorteD
end  # Jekyll
