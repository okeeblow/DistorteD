require 'set'

require 'ttfunk'  # Font metadata extraction
require 'charlock_holmes'  # Text file charset detection

require 'distorted/monkey_business/string'  # String#map
require 'distorted/modular_technology/pango'

require 'distorted/image'

require 'mime/types'

# No need to do all the fancy library versioning in a subclass.
require 'vips'


module Cooltrainer
  module DistorteD
    class Text < Image

      include Cooltrainer::DistorteD::Tech::Pango;


      MEDIA_TYPE = 'text'.freeze

      MIME_TYPES = MIME::Types[/^#{self::MEDIA_TYPE}\/(plain|x-nfo)/, :complete => true].to_set

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


      # Using a numeric key for things for simplicity.
      # TODO: Replace this with Ruby's built-in Encoding class after I have
      # a better idea what I want to do.
      def codepage
        case @encoding
          when 'UTF-8'.freeze then 65001
          when 'Shift_JIS'.freeze then 932
          when 'IBM437'.freeze then 437
          else 1252
        end
      end

      # Return a Pango Markup escaped version of the document.
      def to_pango
        # https://developer.gnome.org/glib/stable/glib-Simple-XML-Subset-Parser.html#g-markup-escape-text
        escaped = @contents.map{ |c|
          g_markup_escape_char(c)
        }
        if spacing == :monospace
          "<tt>" << escaped << "</tt>"
        else
          escaped
        end
      end

      def initialize(src, encoding: nil, font: nil, spacing: nil, dpi: ATTRS_DEFAULT[:dpi])
        @src = src
        @liquid_spacing = spacing

        # VIPS makes us provide the text content as a single variable,
        # so we may as well just one-shot File.read() it into memory.
        # https://kunststube.net/encoding/
        contents = File.read(@src)

        # It's not easy or even possible in some cases to tell the "true" codepage
        # we should use for any given text document, but using character detection
        # is worth a shot if the user gave us nothing.
        detected = CharlockHolmes::EncodingDetector.detect(contents)
        @encoding = (encoding || detected[:encoding] || 'UTF-8'.freeze).to_s
        @contents = CharlockHolmes::Converter.convert(contents, @encoding, 'UTF-8'.freeze)

        # Set the shorthand symbol key for our chosen font.
        @font = font&.to_sym || self.singleton_class.const_get(:CODEPAGE_FONT)[codepage].first

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
        @font_meta = TTFunk::File.open(font_path)

        # https://libvips.github.io/libvips/API/current/libvips-create.html#vips-text
        @image = Vips::Image.text(
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
            :spacing => @font_meta.line_gap,
            :justify => true,  # Requires libvips 8.8
            :dpi => dpi.to_i,
          },
        )
      end

      protected

      # Return the String absolute path to the TTF file
      def font_path
        File.join(
          File.dirname(__FILE__),  # distorted
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
        self.singleton_class.const_get(:FONT_CODEPAGE)&.dig(@font).to_s
      end

      # Returns the basename (with file extension) of our font.
      def font_filename
        self.singleton_class.const_get(:FONT_FILENAME)&.dig(@font)
      end

      # Returns a boolean for whether or not this font is monospaced.
      # true == monospace
      # false == proportional
      def spacing
        # Monospace fonts will (read: should) have the same width
        # for every glyph, so we can tell a monospace font by
        # checking if a deduplicated widths table has size == 1:
        # irb(main)> font.horizontal_metrics.widths.count
        # => 256
        # irb(main)> font.horizontal_metrics.widths.uniq.compact.length
        # => 1
        @font_meta.horizontal_metrics.widths.uniq.compact.length == 1 ? :monospace : :proportional
      end

      # Returns the Family and Subfamily as one string suitable for libvips
      def font_name
        "#{@font_meta.name.font_family.first.encode('UTF-8')} #{@font_meta.name.font_subfamily.first.encode('UTF-8')}"
      end

      # Returns the Pango-Markup-encoded UTF-8 String version + revision of the font
      def font_version
        g_markup_escape_text(@font_meta.name&.version&.first&.encode('UTF-8').to_s)
      end

      # Returns the Pango-Markup-encoded UTF-8 String font file description
      def font_description
        g_markup_escape_text(@font_meta.name&.description&.first&.encode('UTF-8').to_s)
      end

      # Returns the Pango-Markup-encoded UTF-8 String copyright information of the font
      def font_copyright
        g_markup_escape_text(@font_meta.name&.copyright&.first&.encode('UTF-8').to_s)
      end

    end  # Text
  end  # DistorteD
end  # Cooltrainer
