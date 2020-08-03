require 'set'

# Font metadata extraction
require 'ttfunk'

# No need to do all the fancy library versioning in a subclass.
require 'vips'

require 'distorted/checking_you_out'
require 'distorted/text'


module Cooltrainer
  module DistorteD
    class Font < Text

      MEDIA_TYPE = 'font'.freeze

      # TODO: Test OTF, OTB, and others.
      # NOTE: Traditional bitmap fonts won't be supported due to Pango 1.44
      # and later switching to Harfbuzz from Freetype:
      # https://gitlab.gnome.org/GNOME/pango/-/issues/386
      # https://blogs.gnome.org/mclasen/2019/05/25/pango-future-directions/
      MIME_TYPES = CHECKING::YOU::IN(/^#{self::MEDIA_TYPE}\/ttf/)

      ATTRS = Set[
        :alt,
      ]
      ATTRS_VALUES = {
      }
      ATTRS_DEFAULT = {
      }


      # irb(main):089:0> chars.take(5)
      # => [[1, 255], [2, 1], [3, 2], [4, 3], [5, 4]]
      # irb(main):090:0> chars.values.take(5)
      # => [255, 1, 2, 3, 4]
      # irb(main):091:0> chars.values.map(&:chr).take(5)
      # => ["\xFF", "\x01", "\x02", "\x03", "\x04"]
      def to_pango
        output = '' << cr << '<span>' << cr

        output << "<span size='35387'> #{font_name}</span>" << cr << cr

        output << "<span size='24576'> #{font_description}</span>" << cr
        output << "<span size='24576'> #{font_copyright}</span>" << cr
        output << "<span size='24576'> #{font_version}</span>" << cr << cr

        # Print a preview String in using the loaded font. Or don't.
        if @demo
          output << cr << cr << "<span size='24576' foreground='grey'> #{g_markup_escape_text(@demo)}</span>" << cr << cr << cr
        end

        #                        /!\ MANDATORY READING /!\
        # https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6cmap.html
        #
        # "The 'cmap' table maps character codes to glyph indices.
        # The choice of encoding for a particular font is dependent upon the conventions
        # used by the intended platform. A font intended to run on multiple platforms
        # with different encoding conventions will require multiple encoding tables.
        # As a result, the 'cmap' table may contain multiple subtables,
        # one for each supported encoding scheme."
        #
        # Cmap#unicode is a convenient shortcut to sorting the subtables
        # and removing any unusable ones:
        # https://github.com/prawnpdf/ttfunk/blob/master/lib/ttfunk/table/cmap.rb
        #
        # irb(main):174:0> font_meta.cmap.tables.count
        # => 3
        # irb(main):175:0> font_meta.cmap.unicode.count
        # => 2
        @font_meta.cmap.tables.each do |table|
          next if !table.unicode?
          # Each subtable's `code_map` is a Hash map of character codes (the Hash keys)
          # to the glyph IDs from the original font (the Hash's values).
          #
          # Subtable::encode takes:
          #  - a Hash mapping character codes to original font glyph IDs.
          #  - the desired output encoding — Set[:mac_roman, :unicode, :unicode_ucs4]
          #    https://github.com/prawnpdf/ttfunk/blob/master/lib/ttfunk/table/cmap/subtable.rb
          # …and returns a Hash with keys:
          #  - :charmap  — Hash mapping the characters in the input charmap
          #                to a another hash containing both the `:old`
          #                and `:new` glyph ids for each character code.
          #  - :subtable — String encoded subtable for the given encoding.
          encoded = TTFunk::Table::Cmap::Subtable::encode(table&.code_map, :unicode).dig(:charmap)

          output << "<span size='49152'>"

          i = 0
          encoded.each_pair { |c, (old, new)|

            begin
              if glyph = @font_meta.glyph_outlines.for(c)
                # Add a space on either side of the character so they aren't
                # all smooshed up against each other and unreadable.
                output << ' ' << g_markup_escape_char(c) << ' '
                if i >= 15
                  output << cr
                  i = 0
                else
                  i = i + 1
                end
              else
              end
            rescue NoMethodError => nme
              # TTFunk's `glyph_outlines.for()` will raise this if we call it
              # for a codepoint that does not exist in the font, which we will
              # not do because we are enumerating the codepoints in the font,
              # but we should still handle the possibility.
              # irb(main):060:0> font.glyph_outlines.for(555555)
              #
              # Traceback (most recent call last):
              #   6: from /usr/bin/irb:23:in `<main>'
              #   5: from /usr/bin/irb:23:in `load'
              #   4: from /home/okeeblow/.gems/gems/irb-1.2.4/exe/irb:11:in `<top (required)>'
              #   3: from (irb):60
              #   2: from /home/okeeblow/.gems/gems/ttfunk-1.6.2.1/lib/ttfunk/table/glyf.rb:35:in `for'
              #   1: from /home/okeeblow/.gems/gems/ttfunk-1.6.2.1/lib/ttfunk/table/loca.rb:35:in `size_of'
              # NoMethodError (undefined method `-' for nil:NilClass)
            end
          }

          output << '</span>' << cr
        end

        output << '</span>'
        output
      end

      # Return the `src` as the font_path since we aren't using
      # any of the built-in fonts.
      def font_path
        @src
      end

      def initialize(src, demo: nil)
        @src = src
        @demo = demo

        # TODO: Check that src exists, because TTFunk won't and will just
        # give us an unusable object instead.
        @font_meta = TTFunk::File.open(src)

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
            :font => "#{font_name}",
            # Space between lines (in Points).
            :spacing => @font_meta.line_gap,
            # Requires libvips 8.8
            :justify => false,
            :dpi => 144,
          },
        )
      end

    end  # Font 
  end  # DistorteD
end  # Cooltrainer


# Notes on file-format specifics and software-library-specifics
#
# # TTF (via TTFunk)
# 
# ## Cmap
#
# Each TTFunk::Table::Cmap::Format<whatever> class responds to `:supported?`
# with its own internal boolean telling us if that Format is usable in TTFunk.
# This has nothing to do with any font file itself, just the library code.
# irb(main)> font.cmap.tables.map{|t| t.supported?}
# => [true, true, true]
#
# Any subclass of TTFunk::Table::Cmap::Subtable responds to `:unicode?`
# with a boolean calculated from the instance `@platform_id` and `@encoding_id`,
# and those numeric IDs are assigned to the symbolic (e.g. `:macroman`) names in:
# https://github.com/prawnpdf/ttfunk/blob/master/lib/ttfunk/table/cmap/subtable.rb
# irb(main)> font.cmap.tables.map{|t| t.unicode?}
# => [true, false, true]
# 
