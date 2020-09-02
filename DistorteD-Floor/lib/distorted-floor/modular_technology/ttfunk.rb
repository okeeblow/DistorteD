require 'ttfunk'

module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::TTFunk

  def to_ttfunk
    # TODO: Check that src exists, because TTFunk won't and will just
    # give us an unusable object instead.
    @ttfunk_file ||= TTFunk::File.open(font_path)
  end

  # Returns a boolean for whether or not this font is monospaced.
  # true == monospace
  # false == proportional
  def font_spacing
    # Monospace fonts will (read: should) have the same width
    # for every glyph, so we can tell a monospace font by
    # checking if a deduplicated widths table has size == 1:
    # irb(main)> font.horizontal_metrics.widths.count
    # => 256
    # irb(main)> font.horizontal_metrics.widths.uniq.compact.length
    # => 1
    to_ttfunk.horizontal_metrics.widths.uniq.compact.length == 1 ? :monospace : :proportional
  end

  # Returns the Family and Subfamily as one string suitable for libvips
  def font_name
    "#{to_ttfunk.name.font_family.first.encode('UTF-8')} #{to_ttfunk.name.font_subfamily.first.encode('UTF-8')}"
  end

  # Returns the Pango-Markup-encoded UTF-8 String version + revision of the font
  def font_version
    g_markup_escape_text(to_ttfunk.name&.version&.first&.encode('UTF-8').to_s)
  end

  # Returns the Pango-Markup-encoded UTF-8 String font file description
  def font_description
    g_markup_escape_text(to_ttfunk.name&.description&.first&.encode('UTF-8').to_s)
  end

  # Returns the Pango-Markup-encoded UTF-8 String copyright information of the font
  def font_copyright
    g_markup_escape_text(to_ttfunk.name&.copyright&.first&.encode('UTF-8').to_s)
  end

end
