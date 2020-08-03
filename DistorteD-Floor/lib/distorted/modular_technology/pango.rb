module Cooltrainer
  module DistorteD
    module Tech
      module Pango

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

        # Returns a Pango-escaped Carriage Return.
        # Use this for linebreaking Pango Markup output.
        def cr
          g_markup_escape_char(0x0D)
        end

        # Returns a Pango-escapped Line Feed.
        # This isn't used/needed for anything with Pango
        # but it felt weird to include CR and not LF lmao
        def lf
          g_markup_escape_char(0x0A)
        end

        # Returns a Pango'escaped CRLF pair.
        # Also not needed for anything.
        def crlf
          cr << lf
        end

        # "Modified UTF-8" uses a normally-illegal byte sequence
        # to encode the NULL character so 0x00 can exclusively
        # be a string terminator.
        def overlong_null
          [0xC0, 0x80].pack('C*').force_encoding('UTF-8')
        end

        # The char-by-char actual function used by g_markup_escape_text
        def g_markup_escape_char(c)
          # I think a fully-working version of this function would
          # be as simple as `sprintf('&#x%x;', c.ord)` ALL THE THINGS,
          # but I want to copy the structure of the C implementation
          # as closely as possible, which means using the named escape
          # sequences for common characters and separating the
          # Latin-1 Supplement range from the other
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
          when 0x80..0x84, 0x86..0x9f
            # The original C implementation separates this range
            # from the above range due to its need to handle the
            # UTF control character bytes with gunichar:
            # https://wiki.tcl-lang.org/page/UTF%2D8+bit+by+bit
            # https://www.fileformat.info/info/unicode/utf8.htm
            # Ruby has already done this for us here :)
            sprintf('&#x%x;', c.ord)
          when 0x0 # what's this…?
            # Avoid a `ArgumentError: string contains null byte`
            # by not printing one :)
          else
            c
          end
        end

      end  # Pango
    end  # Tech
  end  # DistorteD
end  # Cooltrainer
