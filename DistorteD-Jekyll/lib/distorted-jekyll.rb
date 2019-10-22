require 'pathname'
require 'distorted/floor'
require 'distorted/version'
require 'liquid/tag/parser'

# Tell the user to install the shared library if it's missing.
begin
  require 'vips'
rescue LoadError => le
  # Only match libvips.so load failure
  raise unless le.message =~ /libvips.so/

  # Multiple OS help
  help = <<~INSTALL

  Please install the libvips image processing library.

  FreeBSD:
    pkg install graphics/vips

  macOS:
    brew install vips

  Debian/Ubuntu/Mint:
    apt install libvips libvips-dev
  INSTALL

  # Re-raise with install message
  raise $!, "#{help}\n#{$!}", $!.backtrace
end

module Jekyll
  # Tag-specific StaticFile child that handles thumbnail generation.
  class DistorteDImage < Jekyll::StaticFile
    def initialize(
        site,
        base,
        dir,
        name,
        dest,
        collection = nil
    )
      @tag_name = self.class.name.split('::').last
      Jekyll.logger.debug(@tag_name, "base is #{base}")
      Jekyll.logger.debug(@tag_name, "dir is #{dir}")
      Jekyll.logger.debug(@tag_name, "name is #{name}")
      Jekyll.logger.debug(@tag_name, "dest is #{dest}")
      @base = base
      @dir = dir
      @name = name
      @dest = dest
      # Constructor args for Jekyll::StaticFile:
      # site - The Jekyll Site object
      # base - The String path to the generated `_site` directory.
      # dir  - The String path for generated images, aka the page URL.
      # name - The String filename for one generated or original image.
      super(
        site,
        base,
        dir,
        name
      )

      @dimensions = site.config['distorted']['image']

      # Tell Jekyll we modified this file so it will be included in the output.
      @modified = true
      @modified_time = Time.now
    end

    # dest: string realpath to `_site_` directory
    def destination(dest, suffix = nil)
      File.join(@dest, Cooltrainer::DistortedFloor::image_name(@name, suffix))
    end

    # dest: string realpath to `_site_` directory
    def write(dest)
      Jekyll.logger.debug(@tag_name, "Writing filez to #{dest}")
      orig_dest = destination(dest)
      return false if File.exist?(orig_path) && !modified?

      self.class.mtimes[path] = mtime

      FileUtils.mkdir_p(File.dirname(orig_dest))
      FileUtils.rm(orig_dest) if File.exist?(orig_dest)

      orig = Vips::Image.new_from_file orig_path

      Jekyll.logger.debug(@tag_name, "Rotating #{@name} if tagged.")
      orig = orig.autorot

      # Nuke the entire site from orbit. It's the only way to be sure.
      orig.get_fields.grep(/exif-ifd/).each {|field| orig.remove field}

      orig.write_to_file orig_dest

      for d in @dimensions
        ver_dest = destination(dest, d['tag'])
        Jekyll.logger.debug(@tag_name, "Writing #{d['width']}px version to #{ver_dest}")
        ver = orig.thumbnail_image(d['width'])
        ver.write_to_file ver_dest
      end

      true
    end

    def modified?
      return true
    end

    def orig_path
      File.join(@base, @dir, @name)
    end
  end

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
        template = Liquid::Template.parse(
          File.read(File.join(File.dirname(__FILE__), 'image.liquid'))
        )
        template.render({
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
