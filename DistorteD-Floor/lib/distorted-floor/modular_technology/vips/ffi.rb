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
end


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::Vips; end
module Cooltrainer::DistorteD::Technology::Vips::FFI


  # Returns the default value for any ruby-vips GObject::GValue
  # based on its fundamental GType.
  def self.vips_get_option_default(gtype)
    gtype_id = gtype.is_a?(String) ? GObject::g_type_from_name(gtype) : gtype
    # The `enum` method will actually work for several of these types,
    # e.g. returns `false` for GBool, but let's skip it to avoid the whole,
    # like, FFI/allocation thing.
    case GObject::g_type_fundamental(gtype_id)
    when GObject::GENUM_TYPE
      return self::vips_get_enum_default(gtype_id)
    when GObject::GBOOL_TYPE
      return false
    when GObject::GDOUBLE_TYPE
      return 0.0
    when GObject::GINT_TYPE
      return 0
    when GObject::GUINT64_TYPE
      return 0
    when GObject::GBOXED_TYPE
      return self::vips_get_boxed_default(gtype_id)
    else
      return nil
    end
  end


  # Returns the default for a GEnum derivative by allocating, initializing,
  # and getting the contents of a GValue.
  #
  ## Example:
  # irb> gvp = GObject::GValue.alloc
  # irb> gvp
  # => #<GObject::GValue:0x00005603ba9d4c70>
  # irb> gvp.init(GObject::g_type_from_name('VipsAccess'))
  # => nil
  # irb> GObject::g_type_from_name 'VipsAccess'
  # => 94574011156416
  # irb> gvp.get
  # => :random
  def self.vips_get_enum_default(gtype)
    begin
      gtype_id = gtype.is_a?(String) ? GObject::g_type_from_name(gtype) : gtype
      # Deallocation is automatic when `gvp` goes out of scope.
      gvp = GObject::GValue.alloc
      gvp.init(gtype)
      out = gvp.get
      gvp.unset
      return out
    rescue FFI::NullPointerError => e
      # This is happening for VipsArrayDouble gtype 94691056795136
      # end I don't feel like debugging it rn lololol
      nil
    end
  end


  # Returns a Array of the boxed type (Int, Double, etc)
  def self.vips_get_boxed_default(gtype)
    gtype_id = gtype.is_a?(String) ? GObject::g_type_from_name(gtype) : gtype
    gtype_name = GObject::g_type_name(gtype_id)
    # It's not really correct to explicitly return three values here,
    # but the use of this for `background` colors are the only use rn.
    case gtype_name
    when 'VipsArrayDouble'.freeze
      return [0.0, 0.0, 0.0]
    when 'VipsArrayInt'.freeze
      return [0, 0, 0]
    else
      return []
    end
  end


  # Returns boolean validity for libvips class names,
  # e.g. for validating that a desired Loader/Saver class actually exists!
  def self.vips_object_valid?(fullname)
    # This doesn't seem to raise any Exception on invalid g_type, just returns 0.
    # Use this to cast to a boolean return value:
    #
    # irb(main):243:0> GObject::g_type_from_name('VipsForeignSaveJpegFile')
    # => 94691057381120
    # irb(main):244:0> GObject::g_type_from_name('VipsForeignLoadJpegFile')
    # => 94691057380176
    # irb(main):245:0> GObject::g_type_from_name('VipsForeignLoadJpegFilgfgfgfe')
    # => 0
    GObject::g_type_from_name(fullname) == 0 ? false : true
  end


end
