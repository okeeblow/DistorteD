# Requiring libvips 8.8 for HEIC/HEIF (moo) support, `justify` support in the
# Vips::Image text operator, animated WebP support, and more:
# https://libvips.github.io/libvips/2019/04/22/What's-new-in-8.8.html
VIPS_MINIMUM_VER = [8, 8, 0]

# Tell the user to install the shared library if it's missing.
begin
  require 'vips'

  we_good = false
  if Vips::version(0) >= VIPS_MINIMUM_VER[0]
    if Vips::version(1) >= VIPS_MINIMUM_VER[1]
      if Vips::version(2) >= VIPS_MINIMUM_VER[2]
        we_good = true
      end
    end
  end
  unless we_good
    raise LoadError.new("libvips is older than DistorteD's minimum requirement: needed #{VIPS_MINIMUM_VER.join('.'.freeze)} vs available '#{Vips::version_string}'")
  end

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

require 'set'

require 'mime/types'

module Cooltrainer
  module DistorteD
    class Image

      MEDIA_TYPE = 'image'.freeze

      # SVG support is a sub-class and not directly supported here:
      # `write_to_file': No known saver for '/home/okeeblow/Works/cooltrainer/_site/IIDX-turntable.svg'. (Vips::Error)
      MIME_TYPES = MIME::Types[/^#{MEDIA_TYPE}\/(?!svg)/, :complete => true].to_set

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


      def initialize(src)
        @image = Vips::Image.new_from_file(src)
        @src = src
      end

      def rotate(angle: nil)
        if angle == :auto
          @image = @image&.autorot
        end
      end

      def clean
        # Nuke the entire site from orbit. It's the only way to be sure.
        @image.get_fields.grep(/exif-ifd/).each {|field| @image.remove field}
      end

      def save(dest, width: nil, crop: nil)
        begin
          if width.nil? or width == :full
            return @image.write_to_file(dest)
          elsif width.respond_to?(:to_i)
            ver = @image.thumbnail_image(
              width.to_i,
              **{:crop => crop || ATTRS_DEFAULT[:crop]},
            )
            return ver.write_to_file(dest)
          end
        rescue Vips::Error => v
          if v.message.include?('No known saver')
            # TODO: Handle missing output formats. Replacements? Skip it? Die?
            return nil
          else
            raise
          end
        end
      end  # save

    end  # Image
  end  # DistorteD
end  # Cooltrainer
