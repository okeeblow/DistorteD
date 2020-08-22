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

require 'distorted/checking_you_out'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::Vips

end
