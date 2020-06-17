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
      ATTRS_DEFAULT = Hash.new {|h,k| h[k] = nil} [
        :loading => :eager,
      ]
      ATTRS_VALUES = Hash.new {|h,k| h[k] = h.class.new(&h.default_proc)} [
        :loading => Set[:ATTRS_DEFAULT[:loading.to_s], :lazy],
      ]

      attr_accessor :dest, :dimensions, :types

      def initialize(src, dest: nil, types: nil, dimentions: nil, filenames: nil)
        @image = Vips::Image.new_from_file(src)
        @src = src
        @dest = dest || File.dirname(src)
        @basename = File.basename(src, '.*')
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
