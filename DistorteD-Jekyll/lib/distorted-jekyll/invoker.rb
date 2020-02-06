require 'distorted/floor'
require 'distorted/image'
require 'liquid/tag'
require 'liquid/tag/parser'
require 'mime/types'

module Jekyll
  class DistorteD::Invoker < Liquid::Tag

    include Jekyll::DistorteD::Floor

    # The built-in NotImplementedError is for "when a feature is not implemented
    # on the current platform", so make our own more appropriate one.
    class MediaTypeNotImplementedError < StandardError
      attr_reader :media_type
      def initialize(media_type)
        super("The media type '#{media_type}' is not supported")
      end
    end

    # This list should contain global attributes only, as symbols.
    # The final attribute set will be this + the media-type-specific set.
    # https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes
    ATTRS = Set[:title]

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
      @media_type = mime.media_type

      # Mix in known media_type handlers by prepending our singleton class
      # with the handler module, so module methods override ones defined here.
      # Also combine the handler module's tag attributes with the global ones.
      case @media_type
      when Jekyll::DistorteD::Image::MEDIA_TYPE
        attrs.push(*Jekyll::DistorteD::Image::ATTRS)
        (class <<self; prepend Jekyll::DistorteD::Image; end)
      else
        raise MediaTypeNotImplementedError.new(@media_type)
      end

      # Set instance variables for the combined set of global+handler tag
      # attributes used by this media_type.
      # TODO: Handle missing/malformed tag arguments.
      for attr in attrs
        instance_variable_set('@' + attr.to_s, parsed_arguments[attr])
      end
    end

    def render(context)
      # Get Jekyll Site object back from tag rendering context registers so we
      # can get configuration data and path information from it and
      # then pass it along to our StaticFile subclass.
      site = context.registers[:site]

      # The rendering context's `first` page will be the one that invoked us.
      page_data = context.environments.first['page']

      # Create an instance of the media-appropriate Jekyll::StaticFile subclass.
      #
      # StaticFile args:
      # site - The Jekyll Site object.
      # base - The String path to the Jekyll::Site#source - /home/okeeblow/cooltrainer
      # dir  - The String path between <base> and the file - _posts/2018-10-15-super-cool-post
      # name - The String filename - cool.jpg
      #
      # Our subclass' additional args:
      # dest - The String path to the generated `url` folder of the page HTML output
      base = site.source
      dir = File.dirname(page_data['relative_path'])
      @url = page_data['url']
      site.static_files << self.static_file(site, base, dir, @name, @url)
    end

    def parse_template(site)
      begin
        template = File.join(File.dirname(__FILE__), 'templates', "#{@media_type}.liquid")

        # Jekyll's Liquid renderer caches in 4.0+.
        # Make this a config option or get rid of it and always cache
        # once I have more experience with it.
        cache_templates = true
        if cache_templates
          # file(path) is the caching function, with path as the cache key.
          # The `template` here will be the full path, so no versions of this
          # gem should ever conflict. For example, right now during dev it's:
          # `/home/okeeblow/Works/DistorteD/lib/image.liquid`
          site.liquid_renderer.file(template).parse(File.read(template))
        else
          Liquid::Template.parse(File.read(template))
        end

      rescue Liquid::SyntaxError => l
        l.message
      end
    end

    # Bail out if this is not handled by the module we just mixed in.
    def static_file(site, base, dir, name, url)
      raise MediaTypeNotImplementedError.new(@media_type)
    end

  end
end
