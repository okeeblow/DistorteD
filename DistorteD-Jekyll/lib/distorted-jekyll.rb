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

    def render(context)
      # Get Jekyll Site object back from tag rendering context registers so we
      # can get configuration data and path information from it,
      # then pass it along to our StaticFile subclass.
      site = context.registers[:site]

      # We need a String path for site source, not Pathname, for StaticFile.
      @source = Pathname.new(site.source).to_path

      # Access context data for the page including this tag.
      # Jekyll fills the first `page` Liquid context variable with the complete
      # text content of the page Markdown source, and page variables are
      # available via Hash keys, both for generated options like `path`
      # as well as options explicitly defined in the Markdown front-matter.
      page_data = context.environments.first['page']

      # Extract the pathname of the Markdown source file
      # of the page including this tag, relative to the site source directory.
      # Example: _posts/2019-04-20/laundry-day-is-a-very-dangerous-day.markdown
      markdown_pathname = Pathname.new(page_data['path'])
      Jekyll.logger.debug(
        @tag_name,
        "Initializing for #{@name} in #{markdown_pathname}"
      )
      @srcdir = markdown_pathname.realpath.dirname

      # Generate image destination based on URL of the page invoking this tag,
      # relative to the directory of the generated site.
      # This URL can be explicitly defined in the page's Markdown front-matter,
      # otherwise automatically generated based on the `permalink` config.
      # Assume these paths will only ever be directories containing an index.html,
      # and that these directories are where we want to put our images.
      #
      # Example:
      # A post 2019-06-22-laundry-day.markdown has `url` /laundry-day/ based
      # on my _config.yml setting "permalink: /:title/",
      # so any images displayed in a {% distorted %} tag on that page will end
      # up in the generated path `_site/laundry-day/`.
      @url = page_data['url']

      # Relative path from site source dir to original image's parent dir
      dir = Pathname(@srcdir + @name).relative_path_from(
        Pathname.new(site.source)
      ).dirname.to_path

      # Tell Jekyll about the files we just created
      #
      # StaticFile args:
      # site - The Site.
      # base - The String path to the <source> - /home/okeeblow/cooltrainer
      # dir  - The String path between <base> and the file - _posts/2018-10-15-super-cool-post
      # name - The String filename - cool.jpg
      #
      # Our subclass' additional args:
      # dest - The String path to the generated `url` folder of the page HTML output
      base = Pathname.new site.source
      site.static_files << Jekyll::DistorteD::ImageFile.new(
        site,
        base,
        dir,
        @name,
        @url,
      )
    end

  end
end

# Do the thing.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD::Invoker)
