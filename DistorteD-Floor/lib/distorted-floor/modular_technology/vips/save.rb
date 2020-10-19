
# Requiring libvips 8.8 for HEIC/HEIF (moo) support, `justify` support in the
# Vips::Image text operator, animated WebP support, and more:
# https://libvips.github.io/libvips/2019/04/22/What's-new-in-8.8.html

require 'distorted/modular_technology/triple_counter'
VIPS_MINIMUM_VER = TripleCounter.new(8, 8, 0)

# Tell the user to install the shared library if it's missing.
begin
  require 'vips'
  VIPS_AVAILABLE_VER = TripleCounter.new(Vips::version(0), Vips::version(1), Vips::version(2))

  unless VIPS_AVAILABLE_VER >= VIPS_MINIMUM_VER
    raise LoadError.new(
      "DistorteD needs libvips #{VIPS_MINIMUM_VER}, but the available version is '#{Vips::version_string}'"
    )
  end

rescue LoadError => le
  # Only match libvips.so load failure
  raise unless le.message =~ /libvips.so/

  # Multiple OS help
  help = <<~INSTALL

  Please install the VIPS (libvips) image processing library, version #{VIPS_MINIMUM_VER} or later.

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

require 'distorted/checking_you_out'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::VipsSave

  ATTRIBUTES = {
    :crop => nil,
    :Q => Set[:quality],
  }
  ATTRIBUTES_DEFAULT = {
    :crop => :attention,
  }
  ATTRIBUTES_VALUES = {
    # https://www.rubydoc.info/gems/ruby-vips/Vips/Interesting
    :crop => Set[:none, :centre, :entropy, :attention],
  }

  # Returns a Set of MIME::Types based on libvips VipsForeignSave capabilities.
  # https://libvips.github.io/libvips/API/current/VipsForeignSave.html
  #
  # There is one (only one) native libvips image format, with file extname `.vips`.
  # As I write this—running libvips 8.8—the :get_suffixes function does not include
  # its own '.vips' as a supported extension.
  # There also (as of mid 2020) seems to be no official media-type assigned
  # for VIPS format, so I am going to make one up in CHECKING::YOU::OUT's local-data.
  # - Raw pixel data
  #
  # [RAW]: https://libvips.github.io/libvips/API/current/VipsForeignSave.html#vips-rawload
  # https://libvips.github.io/libvips/API/current/VipsForeignSave.html#vips-csvload
  #
  # Most libvips installations, even very minimally-built ones,
  # will almost certainly support a few very common formats:
  # - JPEG with libjpeg.
  # - PNG with libpng.
  # - GIF with giflib.
  # - WebP with libwebp.
  # - TIFF with libtiff.
  #
  # Normal libvips installations probably also support many less-mainstream formats:
  # - HEIF/HEIC with libheif.
  # - ICC profiles with liblcms2.
  # - Matlab with matio/libhdf5.
  # - FITS★ with cfitsio.
  # - Styled text with Pango/ft2.
  # - Saving GIF/BMP with Magick.
  #     NOTE that GIFs are *loaded* using giflib,
  #     and that BMP loading is unsupported.
  # - Various simple ASCII/binary-based formats with libgsf★
  #   · Comma-separated values
  #   · Netpbm★
  #   · VIPS (non-Matlab) matrices★
  #
  # [NETPBM]: https://en.wikipedia.org/wiki/Netpbm#File_formats
  # [LIBGSF]: https://developer.gnome.org/gsf/
  # [MATRIX]: https://libvips.github.io/libvips/API/current/VipsForeignSave.html#vips-matrixload

  # Vips allows us to query supported *SAVE* types by suffix.
  # There's a simple relationship between filetype and extension since
  # libvips uses the suffix to pick the Saver module.
  #
  # Loader modules, on the other hand, are picked by sniffing the
  # first few bytes of the file, so a list of file extensions for
  # supported loadable formats won't always be complete.
  # For example, SVG and PDF are usually supported as loaders
  # (via rsvg and PDFium/Poppler)
  # https://github.com/libvips/ruby-vips/issues/186
  #
  # irb(main)> Vips.get_suffixes
  # => [".csv", ".mat", ".v", ".vips", ".ppm", ".pgm", ".pbm", ".pfm",
  #     ".hdr", ".dz", ".png", ".jpg", ".jpeg", ".jpe", ".webp", ".tif",
  #     ".tiff", ".fits", ".fit", ".fts", ".gif", ".bmp"]
  OUTER_LIMITS = Vips.get_suffixes.map{ |t|
    # A single call to this will return a Set of MIME::Types for a String input
    CHECKING::YOU::OUT(t)
  }.reduce { |c,t|
    # Flatten the Set-of-Sets-of-Types into a Set-of-Types
    (c || Set[]).merge(t)
  }.keep_if { |t|
    # Filter out any of libvips' supported output Types that aren't
    # actually images (e.g. CSV)
    t.media_type == 'image'
  }

  # Define a to_<mediatype>_<subtype> method for each MIME::Type supported by libvips,
  # e.g. a supported Type 'image/png' will define a method :to_image_png in any
  # context where this module is included.
  self::OUTER_LIMITS.each { |t|
    define_method(t.distorted_method) { |*a, **k, &b|
      vips_save(*a, **k, &b)
    }
  }

  protected

  # Generic Vips saver method, optionally handling resizing and cropping.
  # NOTE: libvips chooses a saver (internally) based on the extname of the destination path.
  def vips_save(dest, width: nil, **kw)
    begin
      if width.nil? or width == :full
        return to_vips_image.write_to_file(dest)
      elsif width.respond_to?(:to_i)
        ver = to_vips_image.thumbnail_image(
          width.to_i,
          # Use `self` namespace for constants so subclasses can redefine
          **{:crop => abstract(:crop)},
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

end
