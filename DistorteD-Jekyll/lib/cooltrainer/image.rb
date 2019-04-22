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
    def initialize(tag_name, arguments, liquid_options)
      super
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

Liquid::Template.register_tag('coolimage', Jekyll::CooltrainerImage)

