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

require 'mime/types'

module Cooltrainer
  class DistorteD
    class Image

      MEDIA_TYPE = 'image'.freeze
      MIME_TYPES = MIME::Types[/^#{MEDIA_TYPE}/, :complete => true]

      # Attributes for our <picture>/<img>.
      # Automatically enabled as attrs for DD Liquid Tag.
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture#Attributes
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img#Attributes
      # https://developer.mozilla.org/en-US/docs/Web/Performance/Lazy_loading
      # :crop is a Vips-only attr
      ATTRS = Set[:alt, :caption, :href, :crop, :loading]

      # Defaults for HTML Element attributes.
      # Not every attr has to be listed here.
      # Many need no default and just won't render.
      ATTRS_DEFAULT = {
        :crop => :attention,
        :loading => :eager,
      }
      ATTRS_VALUES = {
        # https://www.rubydoc.info/gems/ruby-vips/Vips/Interesting
        :crop => Set[:none, :centre, :entropy, :attention],
        :loading => Set[:eager, :lazy],
      }

      attr_accessor :dest, :dimensions, :types

      def initialize(src, dest: nil, types: nil, dimentions: nil, filenames: nil)
        @image = Vips::Image.new_from_file(src)
        @src = src
        @dest = dest || File.dirname(src)
        @basename = File.basename(src, '.*')
        @extname = File.extname(src)
        @dimensions = dimensions || Set[{:tag => :full}]
        @types = types || Set[MIME::Types.type_for(src)]
        @filenames = filenames || Set[@basename]
      end

      def rotate(angle: nil)
        if angle == :auto
          @image = @image.autorot
        end
      end

      def clean
        # Nuke the entire site from orbit. It's the only way to be sure.
        @image.get_fields.grep(/exif-ifd/).each {|field| @image.remove field}
      end

      def generate
        # Output a cleaned/rotated copy of the original file.
        # I might want to make this conditional since I won't always want the
        # input format to also be an output format.
        # Doing that will require some more smarts in the template for
        # default href.
        # Don't forget to change the Static::Image.modified? method too!
        # extname has a leading dot, e.g. File.extname("fart.jpg") => ".jpg"
        only_one_dest = File.join(@dest, "#{@basename}#{@extname}")
        Jekyll.logger.debug('DistorteD Writing:', only_one_dest)
        @image.write_to_file(only_one_dest)

        # Generate every variation for every intended format.
        for t in @types
          for d in @dimensions
            ver_path = File.join(@dest, "#{@basename}-#{d[:tag]&.to_s}.#{t.preferred_extension}")
            Jekyll.logger.debug('DistorteD Writing:', ver_path)
            if d[:tag] == :full
              @image.write_to_file(ver_path)
            elsif d[:width].respond_to?(:to_i)
              ver = @image.thumbnail_image(
                d[:width].to_i,
                **{
                  :crop => (d.dig(:crop) || ATTRS_DEFAULT[:crop]),
                },
              )
              ver.write_to_file(ver_path)
            end
          end
        end
      end

    end  # Image
  end  # DistorteD
end  # Cooltrainer
