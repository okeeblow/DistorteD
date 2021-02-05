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
  # will almost certainly support a few very common formats via the usual libraries:
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
  #     NOTE that GIFs are *loaded* using giflib.
  # - Various simple ASCII/binary-based formats with libgsf★
  #   · Comma-separated values
  #   · Netpbm★
  #   · VIPS (non-Matlab) matrices★
  #
  # [NETPBM]: https://en.wikipedia.org/wiki/Netpbm#File_formats
  # [LIBGSF]: https://developer.gnome.org/gsf/
  # [MATRIX]: https://libvips.github.io/libvips/API/current/VipsForeignSave.html#vips-matrixload

  # Vips allows us to query supported *SAVE* types based on String file suffixes defined in Saver C code.
  # irb(main)> Vips.get_suffixes
  # => [".csv", ".mat", ".v", ".vips", ".ppm", ".pgm", ".pbm", ".pfm",
  #     ".hdr", ".dz", ".png", ".jpg", ".jpeg", ".jpe", ".webp", ".tif",
  #     ".tiff", ".fits", ".fit", ".fts", ".gif", ".bmp"]
  #
  # Vips chooses Loader modules, on the other hand, by sniffing the first few bytes of the file,
  # so a list of file extensions for supported loadable formats won't always be complete.
  # For example, SVG and PDF are usually supported as loaders (via rsvg and PDFium/Poppler)
  # but are nowhere to be found in the Saver-based `:get_suffixes`:
  # https://github.com/libvips/ruby-vips/issues/186
  OUTER_LIMITS = Cooltrainer::DistorteD::Technology::Vips::VipsType::saver_types.keep_if { |type, _operations|
    # Skip textual formats like CVSV image data, and skip mistakenly-detected font Types.
    #
    # Suffix-based Loader detection with the `mime-types` library/database we use
    # causes us to detect a Netpbm PortableFloatmap as an Adobe Printer Font Metrics file:
    # https://en.wikipedia.org/wiki/Netpbm#32-bit_extensions
    type.media_type != 'text'.freeze and not type.sub_type.include?('font'.freeze)
  }.transform_values { |v| v.map(&:options).reduce(&:merge) }

  # Define a to_<mediatype>_<subtype> method for each MIME::Type supported by libvips,
  # e.g. a supported Type 'image/png' will define a method :to_image_png in any
  # context where this module is included.
  self::OUTER_LIMITS.each_key { |t|
    define_method(t.distorted_file_method) { |dest_root, change|
      # Find a VipsType Struct for the saver operation
      vips_operation = Cooltrainer::DistorteD::Technology::Vips::VipsType::saver_for(change.type).first

      # Prepare a Hash of options appropriate for this operation.
      # We explicitly declare all supported VipsArguments, using the FFI-detected
      # default values for keys with no user-given value.
      options = change.to_hash.slice(
        # Get an Array[Symbol] of non-aliased option keys.
        # Loading any aliases' values happens when the Change/Atoms are constructed.
        *vips_operation.options.keep_if { |aka, compound| aka == compound.element }.keys
      ).reject { |k,v|
        # Skip options we manually added (like :crop) or ones with nil values.
        # TODO: Handle all VipsOperation arguments (like :crop) automatically.
        [k == :crop, v.nil?].any?
      }.transform_keys { |k|
        # The `ruby-vips` binding expects hyphenated argument names to be converted to underscores:
        # https://github.com/libvips/ruby-vips/blob/4f696e30796adcc99cbc70ff7fd778439f0cbac7/lib/vips/operation.rb#L78-L80
        k.to_s.gsub('-', '_').to_sym
      }

      # HACK: MagickSave needs us to specify the 'delegate' (ImageMagick-speak)
      # via the :format VipsAttribute that we skipped when generating Compounds.
      # TODO: Use VipsType#parents once it exists instead of checking :include? on a String.
      # TODO: Choose the delegate more directly/intelligently than by just downcasing the sub_type,
      # e.g. 'GIF -> 'gif'. It does work, but this seems fragile.
      if vips_operation.to_s.include?('VipsForeignSaveMagick')
        options.store(:format, change.type.sub_type.downcase)
      end

      loaded_image = to_vips_image(change)

      # Assume the first destination_path has a :nil limit-break.
      change.paths(dest_root).zip(Array[nil].concat(change.breaks)).each { |(dest_path, width)|
        # Chain a call to VipsThumbnailImage into our input Vips::Image iff we were given a width.
        # TODO: Exand this to aarbitrary other operations and consume their options Hash e.g.
        # Cooltrainer::DistorteD::Technology::Vips::VipsType.new(:VipsThumbnailImage).options
        input_image = (width or not [nil, :none].include?(change.to_hash.fetch(:crop, nil))) ?
          loaded_image.thumbnail_image(to_vips_image.width, crop: change.to_hash.fetch(:crop, :none)) :
          loaded_image
        # Do the thing.
        Vips::Operation.call(
          # `:vips_call` expects the operation_name to be a String:
          # https://libvips.github.io/libvips/API/current/VipsOperation.html#vips-call
          vips_operation.name.to_s,
          # Write what Vips::Image, to where?
          [input_image, dest_path],
          # Operation-appropriate options Hash
          options,
          # `:options_string`, unused since we have everything in our Hash.
          ''.freeze,
        )
      }

      # Vips::Image#write_gc is a private method, but the built-in
      # :write_to_file/:write_to_buffer methods call it, so we should call it too.
      loaded_image.send(:write_gc)
    }
  }

end
