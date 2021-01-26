# Requiring libvips 8.8 for HEIC/HEIF (moo) support, `justify` support in the
# Vips::Image text operator, animated WebP support, and more:
# https://libvips.github.io/libvips/2019/04/22/What's-new-in-8.8.html
require 'distorted/triple_counter'
VIPS_MINIMUM_VER = TripleCounter.new(8, 8, 0)

# Tell the user to install the shared library if it's missing or too old.
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

# FFI Struct layout to read a VipsObject class summary.
# Based on https://github.com/libvips/ruby-vips/issues/186#issuecomment-433691412
module Vips
  attach_function :vips_class_find, [:string, :string], :pointer
  attach_function :vips_object_summary_class, [:pointer, :pointer], :void

  class BufStruct < ::FFI::Struct
    layout :base, :pointer,
           :mx, :int,
           :i, :int,
           :full, :bool,
           :lasti, :int,
           :dynamic, :bool
  end

end

module GObject
  # Fundamental types not already defined in ruby-vips' `lib/vips.rb`
  GBOXED_TYPE = g_type_from_name('GBoxed')

  # Attach to functions that aren't already attached in `lib/vips/object.rb`,
  # `lib/vips/operation.rb`, `lib/vips/gvalue.rb`, `lib/vips/gobject.rb`,
  # or some other related file.
  attach_function :g_param_spec_get_default_value, [:pointer], GValue
end
