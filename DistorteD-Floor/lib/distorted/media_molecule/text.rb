require 'set'

require 'charlock_holmes'  # Text file charset detection

require 'distorted/monkey_business/string'  # String#map
require 'distorted/modular_technology/pango'
require 'distorted/modular_technology/ttfunk'
require 'distorted/modular_technology/vips_save'

require 'distorted/checking_you_out'
require 'distorted/injection_of_love'
require 'distorted/molecule/image'



module Cooltrainer
  module DistorteD
    module Text


      LOWER_WORLD = CHECKING::YOU::IN(/^text\/(plain|x-nfo)/)
      OUTER_LIMITS = CHECKING::YOU::IN(/^text\/(plain|x-nfo)/)

      ATTRS = Set[
        :alt,
        :crop,
        :font,
        :encoding,
        :spacing,
        :dpi,
      ]
      ATTRS_VALUES = {
        :spacing => Set[:monospace, :proportional],
      }
      ATTRS_DEFAULT = {
        :crop => :none,
        :dpi => 144,
      }

      # Track supported fonts by codepage.
      # Avoid renaming these from the original archives / websites.
      # Try not to go nuts here bloating the size of our Gem for a
      # very niche feature, but I want to ensure good coverage too.
      #
      # Treat codepage 8859 documents as codepage 1252 to avoid breaking smart-
      # quotes and other printable chars in 1252 that are control chars in 8859.
      # https://encoding.spec.whatwg.org/#names-and-labels
      #
      # Numeric key for UTF-8 is codepage 65001 like Win32:
      # https://docs.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
      FONT_FILENAME = {
        :anonpro => 'Anonymous Pro.ttf'.freeze,
        :anonpro_b => 'Anonymous Pro B.ttf'.freeze,
        :anonpro_bi => 'Anonymous Pro BI.ttf'.freeze,
        :anonpro_i => 'Anonymous Pro I.ttf'.freeze,
        :lessperfectdosvga => 'LessPerfectDOSVGA.ttf'.freeze,
        :moreperfectdisvga => 'MorePerfectDOSVGA.ttf'.freeze,
        :perfectdosvgawin => 'Perfect DOS VGA 437 Win.ttf'.freeze,
        :mona => 'mona.ttf'.freeze,
        :perfectdosvga => 'Perfect DOS VGA 437.ttf'.freeze,
        :profont => 'ProFontWindows.ttf'.freeze,
        :profont_b => 'ProFontWindows-Bold.ttf'.freeze,
      }
      # Certain fonts are more suitable for certain codepages,
      # so track each codepage's available fonts…
      CODEPAGE_FONT = {
        65001 => [
          :anonpro,
          :anonpro_b,
          :anonpro_bi,
          :anonpro_i,
        ],
        1252 => [
          :lessperfectdosvga,
          :moreperfectdosvga,
          :perfectdosvgawin,
        ],
        932 => [
          :mona,
        ],
        850 => [
          :profont,
          :profont_b,
        ],
        437 => [
          :perfectdosvga,
        ],
      }
      # …as well as the inverse, the numeric codepage for each font:
      FONT_CODEPAGE = CODEPAGE_FONT.reduce(Hash.new([])) { |memo, (key, values)|
        values.each { |value| memo[value] = key }
        memo
      }

      self::OUTER_LIMITS.each { |t|
        define_method(t.distorted_method) { |*a, **k, &b|
          copy_file(*a, **k, &b)
        }
      }

      include Cooltrainer::DistorteD::Technology::Pango
      include Cooltrainer::DistorteD::Technology::TTFunk
      include Cooltrainer::DistorteD::Technology::VipsSave
      include Cooltrainer::DistorteD::InjectionOfLove

      # Using a numeric key for things for simplicity.
      # TODO: Replace this with Ruby's built-in Encoding class after I have
      # a better idea what I want to do.
      def codepage
        case text_file_encoding
          when 'UTF-8'.freeze then 65001
          when 'Shift_JIS'.freeze then 932
          when 'IBM437'.freeze then 437
          else 1252
        end
      end

      # Return a Pango Markup escaped version of the document.
      def to_pango
        # https://developer.gnome.org/glib/stable/glib-Simple-XML-Subset-Parser.html#g-markup-escape-text
        escaped = text_file_utf8_content.map{ |c|
          g_markup_escape_char(c)
        }
        if font_spacing == :monospace
          "<tt>" << escaped << "</tt>"
        else
          escaped
        end
      end

      def initialize(src, encoding: nil, font: nil, spacing: nil, dpi: ATTRS_DEFAULT[:dpi])
        @src = src
        @encoding = encoding
        @liquid_spacing = spacing
        @dpi = dpi
      end

      protected

      def text_file_content
        # VIPS makes us provide the text content as a single variable,
        # so we may as well just one-shot File.read() it into memory.
        # https://kunststube.net/encoding/
        @text_file_content ||= File.read(path)
      end

      def text_file_utf8_content
        CharlockHolmes::Converter.convert(text_file_content, text_file_encoding, 'UTF-8'.freeze)
      end

      def text_file_encoding
        # It's not easy or even possible in some cases to tell the "true" codepage
        # we should use for any given text document, but using character detection
        # is worth a shot if the user gave us nothing.
        #
        # TODO: Figure out if/how we can get IBM437 files to not be detected as ISO-8859-1
        detected = CharlockHolmes::EncodingDetector.detect(text_file_content)
        encoding = @text_file_encoding ||= (abstract(:encoding) || detected[:encoding] || 'UTF-8'.freeze).to_s
        encoding
      end

      def vips_font
        # Set the shorthand Symbol key for our chosen font.
        abstract(:font)&.to_sym || self.singleton_class.const_get(:CODEPAGE_FONT)[codepage].first
      end

      def to_vips_image
        # Load font metadata directly from the file so we don't have to
        # duplicate it here to feed to Vips/Pango.
        #
        # irb(main)> font_meta.name.font_name
        # => ["Perfect DOS VGA 437", "\x00P\x00e\x00r\x00f\x00e\x00c\x00t\x00 \x00D\x00O\x00S\x00 \x00V\x00G\x00A\x00 \x004\x003\x007"]
        # irb(main)> font_meta.name.font_family
        # => ["Perfect DOS VGA 437", "\x00P\x00e\x00r\x00f\x00e\x00c\x00t\x00 \x00D\x00O\x00S\x00 \x00V\x00G\x00A\x00 \x004\x003\x007"]
        # irb(main)> font_meta.name.font_subfamily
        # => ["Regular", "\x00R\x00e\x00g\x00u\x00l\x00a\x00r"]
        # irb(main)> font_meta.name.postscript_name
        # => "PerfectDOSVGA437"
        # irb(main)> font_meta.line_gap
        # => 0

        # https://libvips.github.io/libvips/API/current/libvips-create.html#vips-text
        Vips::Image.text(
          # This string must be well-escaped Pango Markup:
          # https://developer.gnome.org/pango/stable/pango-Markup.html
          # However the official function for escaping text is
          # not implemented in Ruby GLib, so we have to do it ourselves.
          to_pango,
          **{
            # String absolute path to TTF
            :fontfile => font_path,
            # It's not enough to just specify the TTF path;
            # we must also specify a font family, subfamily, and size.
            :font => "#{font_name} 16",
            # Space between lines (in Points).
            :spacing => to_ttfunk.line_gap,
            :justify => true,  # Requires libvips 8.8
            :dpi => abstract(:dpi)&.to_i,
          },
        )
      end

      # Return the String absolute path to the TTF file
      def font_path
        File.join(
          File.dirname(__FILE__),  # molecule
          '..'.freeze,  # distorted
          '..'.freeze,  # lib
          '..'.freeze,  # DistorteD-Ruby
          'font'.freeze,
          font_codepage,
          font_filename,
        )
      end

      # Returns the numeric representation of the codepage
      # covered by our font.
      def font_codepage
        self.singleton_class.const_get(:FONT_CODEPAGE)&.dig(vips_font).to_s
      end

      # Returns the basename (with file extension) of our font.
      def font_filename
        self.singleton_class.const_get(:FONT_FILENAME)&.dig(vips_font)
      end

    end  # Text
  end  # DistorteD
end  # Cooltrainer
