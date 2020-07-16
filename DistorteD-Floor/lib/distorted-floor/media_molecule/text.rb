require 'set'

require 'ttfunk'

require 'distorted/monkey_business/string'

require 'mime/types'

module Cooltrainer
  class DistorteD
    class Text < Image

      MEDIA_TYPE = 'text'.freeze

      MIME_TYPES = MIME::Types[/^#{self::MEDIA_TYPE}\/(plain|x-nfo)/, :complete => true].to_set

      ATTRS = Set[
        :alt,
        :font,
        :encoding,
      ]
      ATTRS_VALUES = {
        # Control font selection between the original "Perfect DOS VGA 437" font
        # and the two "Less-" and "More-Perfect" variants:
        # https://www.dafont.com/font-comment.php?file=perfect_dos_vga_437
        # https://laemeur.sdf.org/fonts/
        :font => Set[:less, :more, :perfect, :ansi],
      }
      ATTRS_DEFAULT = {
        :font => :ansi,
        :encoding => 'UTF-8'.freeze,
      }

      # Avoid renaming these from the original archives / websites.
      FONT_FILENAME = {
        :less => 'LessPerfectDOSVGA.ttf'.freeze,
        :more => 'MorePerfectDOSVGA.ttf'.freeze,
        :perfect => 'Perfect DOS VGA 437 Win.ttf'.freeze,
        :ansi => 'Perfect DOS VGA 437.ttf'.freeze,
      }


      # Escape text as necessary for Pango Markup, which is what Vips::Image.text()
      # expects for its argv. This code should be in GLib but is unimplemented in Ruby's:
      #
      # https://ruby-gnome2.osdn.jp/hiki.cgi?Gtk%3A%3ALabel#Markup+%28styled+text%29
      # "The markup passed to Gtk::Label#set_markup() must be valid; for example,
      # literal </>/& characters must be escaped as &lt;, &gt;, and &amp;.
      # If you pass text obtained from the user, file, or a network to
      # Gtk::Label#set_markup(), you'll want to escape it
      # with GLib::Markup.escape_text?(not implemented yet)."
      #
      # Base my own implementation on the original C version found in gmarkup:
      # https://gitlab.gnome.org/GNOME/glib/-/blob/master/glib/gmarkup.c
      def g_markup_escape_text(text)
        text.map{ |c| g_markup_escape_char(c) }
      end

      # The char-by-char actual function used by g_markup_escape_text
      def g_markup_escape_char(c)
        # I think a fully-working version of this function would
        # be as simple `sprintf('&#x%x;', c.ord)`, but I want to copy
        # the C implementation as closely as possible, which means using
        # the named escape sequences for common characters and separating
        # the Unicode control characters (> 0x7f) even though three's no
        # need to in Ruby.
        case c.ord
        when '&'.ord
          '&amp;'
        when '<'.ord
          '&lt;'
        when '>'.ord
          '&gt;'
        when '\''.ord
          '&apos;'
        when '"'.ord
          '&quot;'
        when 0x1..0x8, 0xb..0xc, 0xe..0x1f, 0x7f
          sprintf('&#x%x;', c.ord)
        when 0x7f..0x84, 0x86..0x9f
          sprintf('&#x%x;', c.ord)
        else
          c
        end
      end

      # Return a Pango Markup escaped version of the document.
      def to_pango
        # https://developer.gnome.org/glib/stable/glib-Simple-XML-Subset-Parser.html#g-markup-escape-text
        "<tt>" << @contents.encode('utf-8', :invalid => :replace, :replace => '').map{ |c|
          g_markup_escape_char(c)
        } << "</tt>"
      end

      def initialize(src, font: ATTRS_DEFAULT[:font], encoding: ATTRS_DEFAULT[:encoding])
        @src = src
        # VIPS makes us provide the text content as a single variable,
        # so we may as well just one-shot File.read() it into memory.
        @contents = File.read(src, **{:encoding => encoding.to_s})
        @font = font

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
        font_meta = TTFunk::File.open(font_filename(@font))

        # https://libvips.github.io/libvips/API/current/libvips-create.html#vips-text
        @image = Vips::Image.text(
          # This string must be well-escaped Pango Markup:
          # https://developer.gnome.org/pango/stable/pango-Markup.html
          # However the official function for escaping text is
          # not implemented in Ruby GLib, so we have to do it ourselves.
          to_pango,
          **{
            # String absolute path to TTF
            :fontfile => font_filename(@font),
            # It's not enough to just specify the TTF path;
            # we must also specify a font family, subfamily, and size.
            :font => "#{font_meta.name.font_family.first} #{font_meta.name.font_subfamily.first} 16",
            # Space between lines (in Points)
            :spacing => font_meta.line_gap,
            # Requires libvips 8.8
            :justify => true,
          },
        )
      end

      # Return the String absolute path to the TTF file
      def font_filename(font)
        File.join(
          File.dirname(__FILE__),
          'font'.freeze,
          'IBM-PC'.freeze,
          FONT_FILENAME[font],
        )
      end

    end  # Text
  end  # DistorteD
end  # Cooltrainer
