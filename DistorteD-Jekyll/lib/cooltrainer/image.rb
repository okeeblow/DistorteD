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
        site_source_path,
        relative_original_image_directory,
        destination_filename,
        page_destination_directory,
        image_pipeline,
        dimensions
    )
      # Construct a Jekyll::StaticFile for this image size, though we haven't
      # yet generated the resized image at `destination_filename`.
      super(
        site,
        site_source_path,
        relative_original_image_directory,
        destination_filename
      )
      @destination_filename = destination_filename
      @page_destination_directory = page_destination_directory

      # Split String arg e.g. "153x426" dimensions into Int list e.g. [153, 426]
      bounding_box = dimensions.split('x').map! { |x| Integer(x) }

      # Resize to the given dimensions, and returning a Vips::Image
      # instead of saving over the original filename.
      resized_image = image_pipeline.resize_to_limit(
        *bounding_box
      ).call(save: false)

      # We must use the [pre, post] Array argument to ensure the tempfile
      # includes the same extension as the original file.
      # Vips uses file extension to determine its saver format.
      temp_file = Tempfile.new([
        File.basename(destination_filename),
        File.extname(destination_filename)
      ])

      # Write the Vips::Image to the size-specific filename after resizing.
      resized_image.write_to_file temp_file.path
      Jekyll.logger.debug("ImageFile", "Wrote #{temp_file.path} #{bounding_box}")
      @temp_file_path = temp_file.path

      # Tell Jekyll we modified this file so it will be included in the output.
      @modified = true
      @modified_time = Time.now
    end

    def modified?
      return true
    end

    def path
      Jekyll.logger.debug("ImageFile", "Using temp file #{@temp_file_path}")
      return @temp_file_path
    end

    def destination(dest)
      File.join(@page_destination_directory, @destination_filename)
    end
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
      @original_image_filename = parsed_arguments[:argv1]
      @alt = parsed_arguments[:alt]
      @title = parsed_arguments[:title]
      @url = parsed_arguments[:url]
      @caption = parsed_arguments[:caption]
    end

    def render(context)
      # Pull Jekyll site object back from context registers because we need
      # to pass it to the ImageFile created for each size.
      site = context.registers[:site]

      # Get image size name/dimension hash from config.
      # Example:
      # {
      #   "thumbnail"=>"400x250",
      #   "medium"=>"800x500",
      #   "large"=>"1200x750"
      # }
      sizes = site.config['cool_image']['sizes']
      Jekyll.logger.debug(@tag_name, sizes)

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
        "Initializing for #{@original_image_filename} in #{markdown_pathname}"
      )

      # Get the complete path to the original image file we're resizing.
      # This must be a realpath because it gets compared to the built-in
      # Jekyll::Site.source with `relative_path_from` which requires a realpath.
      original_image_pathname = markdown_pathname.realpath.dirname + @original_image_filename

      # Test (again) that the original image exists and bail out if not.
      if FileTest.exist?(original_image_pathname)
        Jekyll.logger.debug(@tag_name, "#{original_image_pathname} exists")
        @original_image_pathname = original_image_pathname
      else
        Jekyll.logger.error(@tag_name, "#{original_image_pathname} does not exist")
        raise ImageNotFoundError.new(original_image_pathname)
      end

      # Access the final generated URL of the page including this tag,
      # relative to the directory of the generated site.
      # This URL can be explicitly defined in the page's Markdown front-matter,
      # but if not it will be automatically generated.
      # Assuming these paths will only ever be directories,
      # and these directories are where we want to put our images.
      #
      # Example: 2019-06-22-laundry-day.markdown has `url` /laundry-day/
      page_destination_directory = site.dest + page_data["url"]
      Jekyll.logger.debug(
        @tag_name,
        "Generated images will be placed in #{page_destination_directory}"
      )

      # We need a String path for site source, not Pathname.
      site_source_path = Pathname.new(site.source).to_path

      # Relative path from site source dir to original image's parent dir
      relative_original_image_path = original_image_pathname.relative_path_from(
        Pathname.new(site.source)
      ).dirname.to_path

      # Load original image into a processing pipeline to pass to each size
      image_pipeline = ImageProcessing::Vips.source(
        original_image_pathname.to_path
      )

      # Generate a StaticFile for each size
      generated = sizes.map {
        |size_name, dimensions|
        ImageFile.new(
          site,
          site_source_path,
          relative_original_image_path,
          image_name(@original_image_filename, size_name),
          page_destination_directory,
          image_pipeline,
          dimensions
        )
      }

      # Tell Jekyll about the files we just created
      site.static_files.concat(generated)
      # TODO: Copy the original file too if we don't have jekyll-postfiles

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

    # Generate a size-specific filename for an image.
    # Ex: "tidd.png" for setting "large"=>"1200x750" = "tidd-large.png"
    def image_name(image_filename, size_name)
      return [
        File.basename(image_filename, ".*"),
        "-",
        size_name,
        File.extname(image_filename)
      ].join()
    end
  end
end

# Do the thing.
Liquid::Template.register_tag('coolimage', Jekyll::CooltrainerImage)

