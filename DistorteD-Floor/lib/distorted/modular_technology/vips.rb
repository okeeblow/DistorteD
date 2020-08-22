# Requiring libvips 8.8 for HEIC/HEIF (moo) support, `justify` support in the
# Vips::Image text operator, animated WebP support, and more:
# https://libvips.github.io/libvips/2019/04/22/What's-new-in-8.8.html
VIPS_MINIMUM_VER = [8, 8, 0]

# Tell the user to install the shared library if it's missing.
begin
  require 'vips'
  unless Vips.at_least_libvips?(VIPS_MINIMUM_VER[0], VIPS_MINIMUM_VER[1])
    raise LoadError.new("libvips is older than DistorteD's minimum requirement: needed #{VIPS_MINIMUM_VER.join('.'.freeze)} vs available '#{Vips::version_string}'")
  end

rescue LoadError => le
  # Only match libvips.so load failure
  raise unless le.message =~ /libvips.so/

  # Multiple OS help
  help = <<~INSTALL

  Please install the libvips image processing library.

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
module Cooltrainer::DistorteD::Technology::Vips


  # Returns a Set of MIME::Types supported by libvips
  def self.supported_types
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

    Vips.get_suffixes.map{ |t|
      # A single call to this will return a Set for a String input
      CHECKING::YOU::OUT(t)
    }.reduce { |c,t|
      # Flatten the Set-of-Sets-of-Types into a Set-of-Types
      (c || Set[]).merge(t)
    }.keep_if { |t|
      # Filter out any Types that aren't images (e.g. CSV)
      t.media_type == 'image'
    }
  end

end
