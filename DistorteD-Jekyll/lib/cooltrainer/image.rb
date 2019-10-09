require "tempfile"
require "pathname"
require "cooltrainer/image/version"
require "liquid/tag/parser"
require "image_processing/vips"

# Tell the user to install the shared library if it's missing.
begin
  require "vips"
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
  class ImageFile < Jekyll::StaticFile
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
      # We will instantiate one Jekyll::StaticFile for each size generated
      # from our original full-resolution image. One StaticFile instance
      # tracks one actual file in the final `_site_ directory.
      #
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

      dimensions = site.config['cool_image']['dimensions']

      # Load original image into a processing pipeline to pass to each size
      image_pipeline = ImageProcessing::Vips.source(
        File.join(base, dir, name)
      )

      # Resize to the given dimensions, and returning a Vips::Image
      # instead of saving over the original filename.
      resized_image = image_pipeline.resize_to_limit(
        200, 200
      ).call(save: false)

      # Write the Vips::Image to the size-specific filename after resizing.
      resized_name = File.join(dest, File.basename(name, ".*") + '-lol' + File.extname(name))
      resized_file = File.new(resized_name, "w")
      resized_file.close

      resized_image.write_to_file resized_name

      # Tell Jekyll we modified this file so it will be included in the output.
      @modified = true
      @modified_time = Time.now
    end

    # dest: string realpath to `_site_` directory
    def destination(dest, suffix = nil)
      if suffix
        File.join(@dest, File.basename(@name, ".*") + '-' + suffix + File.extname(@name))
      else
        File.join(@dest, @name)
      end
    end

    # dest: string realpath to `_site_` directory
    def write(dest)
      Jekyll.logger.debug("ImageFile", "Writing filez to #{dest}")
      dest_path = destination(dest)
      return false if File.exist?(dest_path) && !modified?

      self.class.mtimes[path] = mtime

      FileUtils.mkdir_p(File.dirname(dest_path))
      FileUtils.rm(dest_path) if File.exist?(dest_path)
      copy_file(dest_path)

      true
    end

    def modified?
      return true
    end

    #def destination(dest)
    #  File.join(@destdir, @name)
    #end
  end

  class CooltrainerImage < Liquid::Tag

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
      @url = parsed_arguments[:url]
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
      dimensions = site.config['cool_image']['dimensions']
      # TODO: Conditional debug since even that is spammy with many tags.
      Jekyll.logger.debug(@tag_name, dimensions)

      # Access context data for the page including this tag.
      # Jekyll fills the first `page` Liquid context variable with the complete
      # text content of the page Markdown source, and page variables are
      # available via Hash keys, both for generated options like `path`
      # as well as options explicitly defined in the Markdown front-matter.
      page_data = context.environments.first["page"]

      # Extract the pathname of the Markdown source file
      # of the page including this tag, relative to the site source directory.
      # Example: _posts/2019-04-20/laundry-day-is-a-very-dangerous-day.markdown
      markdown_pathname = Pathname.new(page_data["path"])
      Jekyll.logger.debug(
        @tag_name,
        "Initializing for #{@name} in #{markdown_pathname}"
      )
      @srcdir = markdown_pathname.realpath.dirname

      # Access the final generated URL of the page including this tag,
      # relative to the directory of the generated site.
      # This URL can be explicitly defined in the page's Markdown front-matter,
      # but if not it will be automatically generated.
      # Assuming these paths will only ever be directories,
      # and these directories are where we want to put our images.
      #
      # Example: 2019-06-22-laundry-day.markdown has `url` /laundry-day/
      dest = site.dest + page_data["url"]
      Jekyll.logger.debug(
        @tag_name,
        "Generated images will be placed in #{dest}"
      )

      # Relative path from site source dir to original image's parent dir
      dir = Pathname(@srcdir + @name).relative_path_from(
        Pathname.new(site.source)
      ).dirname.to_path

      # Tell Jekyll about the files we just created
      # TODO: Copy the original file too if we don't have jekyll-postfiles
      # StaticFile args:
      # site - The Site.
      # base - The String path to the <source> - /srv/jekyll
      # dir  - The String path between <source> and the file - _posts/somedir
      # name - The String filename of the file - cool.svg
      # dest - The String path to the containing folder of the document which is output
      base = Pathname.new site.source
      site.static_files << ImageFile.new(
        site,
        base,
        dir,
        @name,
        dest
      )

      template = Liquid::Template.parse(
        File.read(File.join(File.dirname(__FILE__), "image.liquid"))
      )
      return template.render({
        "image" => @image,
        "alt" => @alt,
        "title" => @title,
        "url" => @url,
        "caption" => @caption,
      })
    end
  end
end

# Do the thing.
Liquid::Template.register_tag('coolimage', Jekyll::CooltrainerImage)

