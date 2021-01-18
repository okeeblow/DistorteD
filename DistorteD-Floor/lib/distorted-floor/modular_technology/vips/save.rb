require 'set'

require 'distorted/checking_you_out'

require 'distorted/modular_technology/vips/operation'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::Vips::Save


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
  # https://libvips.github.io/libvips/API/current/VipsForeignSave.html
  #
  # Loader modules, on the other hand, are usually picked by sniffing the
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
  #
  # Use our own FFI code path for consistency with Vips::Load.
  # Functionally this is identical to the built-in :get_suffixes.
  VIPS_SAVERS = Cooltrainer::DistorteD::Technology::Vips::vips_get_types(
    Cooltrainer::DistorteD::Technology::Vips::TOP_LEVEL_SAVER
  ).keep_if { |t|
    # Filter out any of libvips' supported output Types that aren't
    # actually images (e.g. CSV and Type1 fonts) while allowing
    # some 'application' media-types for vendor image formats.
    # TODO: Make this more robust/automatic.
    t.media_type != 'text'.freeze and not t.sub_type.include?('font'.freeze)
  }

  OUTER_LIMITS = VIPS_SAVERS.each_with_object(Hash.new) { |type, types|
    types[type] = Cooltrainer::DistorteD::Technology::Vips::vips_get_options(
      Vips::vips_foreign_find_save(".#{type.preferred_extension}")
    )
  }

  # Define a to_<mediatype>_<subtype> method for each MIME::Type supported by libvips,
  # e.g. a supported Type 'image/png' will define a method :to_image_png in any
  # context where this module is included.
  self::OUTER_LIMITS.each_key { |t|
    define_method(t.distorted_file_method) { |dest_root, change|
      vips_save(dest_root, change)
    }
  }

  protected

  # Generic Vips saver method, optionally handling resizing and cropping.
  # NOTE: libvips chooses a saver (internally) based on the extname of the destination path.
  # TODO: String-buffer version of this method using e.g. Image#jpegsave_buffer
  def vips_save(dest_root, change)
    begin
      to_vips_image.write_to_file(change.paths(dest_root).first)
      change.breaks.each { |b|
        ver = to_vips_image.thumbnail_image(
          b.to_int,
          **{:crop => change.crop || :none},
        )
        ver.write_to_file(change.path(dest_root, b))
      }
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
