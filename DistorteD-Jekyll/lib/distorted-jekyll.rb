require 'pathname'
require 'distorted/floor'
require 'distorted/image'
require 'distorted/version'
require 'liquid/tag/parser'

module Jekyll
  class DistorteD < Liquid::Tag

    class ImageNotFoundError < ArgumentError
      attr_reader :image
      def initialize(image)
        super("The specified image path #{image} was not found")
      end
    end

    def initialize(tag_name, arguments, liquid_options)
      super
      # Tag name as given to Liquid::Template.register_tag()
      @tag_name = tag_name

      # Parse arguments with https://github.com/envygeeks/liquid-tag-parser
      parsed_arguments = Liquid::Tag::Parser.new(arguments)

      # name - original image filename
      # alt - String contents of <img alt>
      # title - String contents of <img title>
      # caption - String displayed under image in template.
      @name = parsed_arguments[:argv1]
      @alt = parsed_arguments[:alt]
      @title = parsed_arguments[:title]
      @href = parsed_arguments[:href]
      @caption = parsed_arguments[:caption]
    end

    # This will become render_to_output_buffer(context, output) some day,
    # according to upstream Liquid tag.rb.
    def render(context)
      # Get Jekyll Site object back from tag rendering context registers so we
      # can get configuration data and path information from it,
      # then pass it along to our StaticFile subclass.
      site = context.registers[:site]

      # We need a String path for site source, not Pathname, for StaticFile.
      @source = Pathname.new(site.source).to_path

      # Get image dimension configuration data.
      # TODO: Defaults? What should this tag do with no config?
      # Example:
      # [
      #   {:name=>"thumbnail", width=>400, height=>250, media=>""},
      # ]

      # TODO: Handle failure when config block is missing
      dimensions = site.config['distorted']['image']

      # TODO: Conditional debug since even that is spammy with many tags.
      Jekyll.logger.debug(@tag_name, dimensions)

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
      url = page_data['url']
      dest = site.dest + url
      Jekyll.logger.debug(
        @tag_name,
        "Generated images will be placed in #{dest}"
      )

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
      site.static_files << DistorteDImage.new(
        site,
        base,
        dir,
        @name,
        dest
      )

      # String keys instead of symbols due to YAML config format
      # and Liquid template hash.
      sources = dimensions.map { |d| {
        'name' => Cooltrainer::DistortedFloor::image_name(@name, d['tag']),
        'media' => d['media']
      }}
      Jekyll.logger.debug(@tag_name, "#{@name} <source>s: #{sources}")

      begin
				template = File.join(File.dirname(__FILE__), 'image.liquid')

				# Jekyll's Liquid renderer caches in 4.0+.
				# Make this a config option or get rid of it and always cache
				# once I have more experience with it.
        cache_templates = true
				if cache_templates
					# file(path) is the caching function, with path as the cache key.
					# The `template` here will be the full path, so no versions of this
					# gem should ever conflict. For example, right now during dev it's:
					# `/home/okeeblow/Works/DistorteD/lib/image.liquid`
					picture = site.liquid_renderer.file(template).parse(File.read(template))
				else
					picture = Liquid::Template.parse(File.read(template))
				end

        picture.render({
          'name' => @name,
          'path' => url,
          'alt' => @alt,
          'title' => @title,
          'href' => @href,
          'caption' => @caption,
          'sources' => sources,
        })
      rescue Liquid::SyntaxError => l
        # TODO: Only in dev
        l.message
      end
    end
  end
end

# Do the thing.
Liquid::Template.register_tag('distorted', Jekyll::DistorteD)
