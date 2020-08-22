
require 'set'

require 'distorted/checking_you_out'
require 'distorted/modular_technology/vips'


module Cooltrainer
  module DistorteD
    class Image

      MEDIA_TYPE = 'image'.freeze
      include Cooltrainer::DistorteD::Technology::Vips

      # SVG support is a sub-class and not directly supported here:
      # `write_to_file': No known saver for '/home/okeeblow/Works/cooltrainer/_site/IIDX-turntable.svg'. (Vips::Error)
      MIME_TYPES = CHECKING::YOU::IN(/^#{MEDIA_TYPE}\/(?!svg)/)

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
              # Use `self` namespace for constants so subclasses can redefine
              **{:crop => crop || self.singleton_class.const_get(:ATTRS_DEFAULT)[:crop]},
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
