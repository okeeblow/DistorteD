require "pathname"
require "cooltrainer/image/version"
require "liquid/tag/parser"

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
  class ImageFiles < Jekyll::StaticFile

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
      @tag_name = tag_name
      parsed_arguments = Liquid::Tag::Parser.new(arguments)
      @image = parsed_arguments[:argv1]
      @alt = parsed_arguments[:alt]
      @title = parsed_arguments[:title]
      @url = parsed_arguments[:url]
      @caption = parsed_arguments[:caption]
    end

    def render(context)
      template = Liquid::Template.parse(
        File.read(File.join(File.dirname(__FILE__), "image.liquid"))
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
      image_path = markdown_path.dirname + @image
      if FileTest.exist?(image_path)
        Jekyll.logger.debug(@tag_name, "#{image_path} exists")
        @image_src_path = image_path
      else
        Jekyll.logger.error(@tag_name, "#{image_path} does not exist")
        # TODO: Enable/disable raising exceptions via a _config.yaml toggle.
        raise ImageNotFoundError.new(image_path)
      end

      # `url` is the intended URL of the final rendered page, relative to the
      # site's root URL. This can be explicitly defined in the Markdown
      # front-matter, otherwise will be automatically generated.
      # Example: /laundry-day/
      page_url = page_data["url"]
      Jekyll.logger.debug(
        @tag_name,
        "Generated images will be placed in _site#{page_url}"
      )
    end
  end
end

Liquid::Template.register_tag('coolimage', Jekyll::CooltrainerImage)

