require 'distorted/image'
require 'liquid/tag/parser'

module Jekyll

  class DistorteD::Invoker < Liquid::Tag

    def initialize(tag_name, arguments, liquid_options)
      super
      # Tag name as given to Liquid::Template.register_tag()
      @tag_name = tag_name

      # Liquid leaves argument parsing totally up to us.
      # Use the envygeeks/liquid-tag-parser library to wrangle them.
      parsed_arguments = Liquid::Tag::Parser.new(arguments)

      # Filename is the only non-keyword argument our tag should ever get.
      # It's spe-shul and gets its own definition outside the attr loop.
      @name = parsed_arguments[:argv1]

      #

      end

    end

  end

end

# Do the thing.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)
