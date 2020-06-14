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

      MEDIA_TYPE = 'image'
      MIME_TYPES = MIME::Types[/^#{MEDIA_TYPE}/, :complete => true]

      attr_accessor :dimensions

      def initialize(src)
        @image = Vips::Image.new_from_file(src)
      end

      def rotate(angle=nil)
        if angle == :auto
          @image = @image.autorot
        end
      end

      def clean
        # Nuke the entire site from orbit. It's the only way to be sure.
        @image.get_fields.grep(/exif-ifd/).each {|field| @image.remove field}
      end

      def generate
        for d in @dimensions
          if d[:tag] == :full
            @image.write_to_file(d[:dest])
          else
            ver = @image.thumbnail_image(d[:width], **{:crop => d[:crop]})
            ver.write_to_file(d[:dest])
          end
        end
      end

    end  # Image
  end  # DistorteD
end  # Cooltrainer
