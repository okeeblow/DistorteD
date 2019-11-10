require 'distorted/floor'
require 'distorted/image'
require 'liquid/tag'
require 'liquid/tag/parser'
require 'mime/types'

module Jekyll
  class DistorteD::Invoker < Liquid::Tag

    include Jekyll::DistorteD::Floor

    # This list should contain global attributes only, as symbols.
    # The final attribute set will be this + the media-type-specific set.
    # https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes
    ATTRS = [:title]

    def initialize(tag_name, arguments, liquid_options)
      super
      # Tag name as given to Liquid::Template.register_tag().
      # Yes, this is redundant considering this same file defines the name.
      @tag_name = tag_name

      # Attributes  will be given to our liquid tag as keyword arguments.
      # Start with the base set of shared attributes defined here in the
      # loader, then push() a handler's additional ATTRs on to it.
      attrs = self.class::ATTRS

      # Liquid leaves argument parsing totally up to us.
      # Use the envygeeks/liquid-tag-parser library to wrangle them.
      parsed_arguments = Liquid::Tag::Parser.new(arguments)

      # Filename is the only non-keyword argument our tag should ever get.
      # It's spe-shul and gets its own definition outside the attr loop.
      @name = parsed_arguments[:argv1]

      # Guess MIME Magic from the filename. For example:
      # `distorted IIDX-Readers-Unboxing.jpg: [#<MIME::Type: image/jpeg>]`
      #
      # Types#type_for can return multiple possibilities for a filename.
      # For example, an XML file: [application/xml, text/xml].
      mime = MIME::Types.type_for(@name)
      Jekyll.logger.debug(@tag_name, "#{@name}: #{mime}")

      # TODO: Properly support multiple MIME types from type_for().
      # For now just take the first since we're mostly working with images.
      mime = mime.first

      # Select handler module based on the detected media type.
      # For an example MIME Type image/jpeg, 
      # `media_type` is 'image' and `sub_type` is 'jpeg'.
      case mime.media_type
      when 'image'
        attrs.push(*Jekyll::DistorteD::Image::ATTRS)
        (class <<self; prepend Jekyll::DistorteD::Image; end)
      end

      # Set instance variables for the combined set of attributes used
      # by this handler.
      # TODO: Handle missing/malformed tag arguments.
      for attr in attrs
        instance_variable_set('@' + attr.to_s, parsed_arguments[attr])
      end
    end
  end
end

# Do the thing.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)
