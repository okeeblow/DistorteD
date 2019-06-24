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
      @image = parsed_arguments[:argv1]
      @alt = parsed_arguments[:alt]
      @title = parsed_arguments[:title]
      @url = parsed_arguments[:url]
      @caption = parsed_arguments[:caption]
    end

    def render(context)
      # Jekyll fills the first `page` Liquid context variable with the complete
      # text content of the page Markdown source, and page variables are
      # available via Hash keys, both for generated options like `path`
      # as well as options explicitly defined in the Markdown front-matter.
      page_data = context.environments.first["page"]

      # `path` is the path of the Markdown source file that included our tag,
      # relative to the project root.
      # Example: _posts/2019-04-20/laundry-day-is-a-very-dangerous-day.markdown
      markdown_path = Pathname.new(page_data["path"])
      Jekyll.logger.debug(
        @tag_name,
        "Initializing CooltrainerImage for #{@image} in #{markdown_path}"
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

