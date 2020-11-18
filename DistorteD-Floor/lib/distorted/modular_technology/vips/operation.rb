require 'vips'

require 'distorted/checking_you_out'
require 'distorted/element_of_media'

# Based on https://github.com/libvips/ruby-vips/issues/186#issuecomment-433691412
module Vips
  attach_function :vips_class_find, [:string, :string], :pointer
  attach_function :vips_object_summary_class, [:pointer, :pointer], :void

  class BufStruct < FFI::Struct
    layout :base, :pointer,
           :mx, :int,
           :i, :int,
           :full, :bool,
           :lasti, :int,
           :dynamic, :bool
  end

end


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::VipsForeign


  # 🄵🄸🄽🄳 🅃🄷🄴 🄲🄾🄼🄿🅄🅃🄴🅁 🅁🄾🄾🄼
  # 🄵🄸🄽🄳 🅃🄷🄴 🄲🄾🄼🄿🅄🅃🄴🅁 🅁🄾🄾🄼
  # 🄵🄸🄽🄳 🅃🄷🄴 🄲🄾🄼🄿🅄🅃🄴🅁 🅁🄾🄾🄼
  Vips::vips_vector_set_enabled(1)


  # All of the actual Loader/Saver classes we need to interact with
  # will be tree children of one of these top-level class categories:
  TOP_LEVEL_LOADER = :VipsForeignLoad
  TOP_LEVEL_SAVER  = :VipsForeignSave


  # This has got to be built in to Ruby-GLib somewhere, right?
  # Remove this if an FFI method is possible to get this mapping.
  G_TYPE_VALUES = {
    :gboolean => Cooltrainer::BOOLEAN_VALUES,
    :gchararray => String,
    :gint => Integer,
  }


  # Store FFI results where possible to minimize memory churn 'n' general fragility.
  @@vips_foreign_types = Hash[]
  @@vips_foreign_suffixes = Hash[]
  @@vips_foreign_options = Hash[]


  # Returns a Set of MIME::Types based on the "supported suffix" lists generated
  # by libvips and our other functions here in this Module.
  def self.vips_get_types(basename)
    @@vips_foreign_types[basename.to_sym] ||= self::vips_get_suffixes(basename).reduce(Set[]) { |types, suffix|
      types.merge(CHECKING::YOU::OUT(suffix))
    }
  end


  # Returns a Set of String filename suffixes supported by a tree of libvips loader/saver classes.
  #
  # The Array returned from self::vips_get_nickname_suffixes will be overloaded
  # with all duplicate suffix possibilities for each Type according to libvips.
  # e.g. 
  # This is unrelated to MIME::Type#preferred_extension!!
  def self.vips_get_suffixes(basename)
    @@vips_foreign_suffixes[basename.to_sym] ||= self::vips_get_suffixes_per_nickname(basename).values.reduce(Set[]) {|n,s| n.merge(s)}
  end


  # Returns a Hash[alias] of Compound attributes supported by a given libvips Loader/Saver class.
  def self.vips_get_options(nickname)
    return Hash if nickname.nil?
    @@vips_foreign_options[nickname.to_sym] ||= self::vips_get_nickname_options(nickname)
  end


  protected


  # Returns a Set of local MIME::Types supported by the given class and any of its children.
  def self.vips_get_types_per_nickname(basename)
    self::vips_get_suffixes_per_nickname(basename).transform_values{|s| CHECKING::YOU::OUT(s)}
  end

  # Returns a Hash[Type] of Set[String] class nicknames supporting that Type.
  def self.vips_get_nicknames_per_type(basename)
    self::vips_get_nickname_types(basename).reduce(Hash.new{|h,k| h[k] = Set[]}) {|memo,(nickname,type_set)|
      type_set.each{ |t|
        memo[t] << nickname
      }
      memo
    }
  end

  # Returns a Hash[String] of Set[String]s containing the
  # supported MediaType filename suffixes for all child classes of
  # either VipsForeignSave or VipsForeignLoad.
  #
  # This is very similar to the built-in Vips::get_suffixes except
  # also allows us to directly inspect Loaders — including Magick!
  #
  # Previously we had to take the Saver suffixes and just assume each had a matching Loader.
  # This was very limiting MediaType support since OpenEXR/OpenSlide/Magick-supported
  # Loader types would not have a Saver suffix and would have no way to be discovered!
  # This also works around Loader type support bugs, e.g. the Magick-based BMP (MS Bitmap)
  # Loader was missing prior to libvips version 8.9.1.,
  # so we can stop checking versions and inserting manual workarounds for those corner cases!
  #
  # The FFI buffer reads will leave us with an overloaded Array containing
  # duplicate suffixes for every supported suffix variation of a given type,
  #   e.g.  ['.jpg', '.jpe', '.jpeg', '.png], '.gif', '.tif', '.tiff' … ]
  def self.vips_get_suffixes_per_nickname(basename)
    nickname_suffixes = Hash[]
    self::vips_get_child_class_nicknames(basename).each{ |nickname|
      # "Search below basename, return the first class whose name or nickname matches."
      # VipsForeign is a basename for savers and loaders alike.
      foreign_class = Vips::vips_class_find('VipsForeign'.freeze, nickname)
      next if foreign_class.null?

      buf_struct = Vips::BufStruct.new
      buf_struct_string = FFI::MemoryPointer.new(:char, 2048)
      buf_struct[:base] = buf_struct_string
      buf_struct[:mx] = 2048

      # Load the human-readable class summary into a given buffer.
      Vips::vips_object_summary_class(foreign_class, buf_struct.pointer)

      class_summary = buf_struct_string.read_string

      suffixes = class_summary.scan(/\.\w+\.?\w+/)
      nickname_suffixes.update({nickname => suffixes.to_set}) unless suffixes.empty?
    }
    nickname_suffixes
  end

  # Returns a Set of String class names for libvips' Loaders/Savers.
  def self.vips_get_child_class_nicknames(basename)
    nicknames = Set[]
    generate_class = Proc.new{ |gtype|
      nickname = Vips::nickname_find(gtype)
      nicknames << nickname if nickname

      # https://libvips.github.io/libvips/API/current/VipsObject.html#vips-type-map
      # "Map over a type's children. Stop when fn returns non-nil and return that value."
      Vips::vips_type_map(gtype, generate_class, nil)
    }
    generate_class.call(GObject::g_type_from_name(basename))
    nicknames
  end

  # Returns a Hash[alias] of attribute Compounds for every optional attribute of a libvips Loader/Saver class.
  #
  # The discarded 'required' attributes are things like filenames that we will handle ourselves in DD.
  # irb> Vips::Introspect.get('jpegload').required_input
  # => [{:arg_name=>"filename", :flags=>19, :gtype=>64}]
  # irb> Vips::Introspect.new('jpegload').required_output
  # => [{:arg_name=>"out", :flags=>35, :gtype=>94062772794288}]
  #
  ## Example using :argument_map:
  # irb> Vips::Operation.new('gifload').argument_map{|a,b,c| p "#{a[:name]} — #{a[:value_type]} — #{GObject::g_type_name(a[:value_type])}"}
  # "filename — 64 — gchararray"
  # "nickname — 64 — gchararray"
  # "out — 94691057294304 — VipsImage"
  # "description — 64 — gchararray"
  # "page — 24 — gint"
  # "n — 24 — gint"
  # "flags — 94691059531296 — VipsForeignFlags"
  # "memory — 20 — gboolean"
  # "access — 94691057417952 — VipsAccess"
  # "sequential — 20 — gboolean"
  # "fail — 20 — gboolean"
  # "disc — 20 — gboolean"
  #
  ## Descriptions are obtained by passing the complete pspec to g_param_get_blurb:
  #   Example:
  # irb> Vips::Operation.new('openexrload').argument_map{|a,b,c| p GObject::g_param_spec_get_blurb(a)}
  # "Filename to load from"
  # "Class nickname"
  # "Output image"
  # "Class description"
  # "Flags for this file"
  # "Force open via memory"
  # "Required access pattern for this file"
  # "Sequential read only"
  # "Fail on first error"
  # "Open to disc"
  def self.vips_get_nickname_options(nickname)
    options = Hash[]
    Vips::Operation.new(nickname).argument_map{ |param_spec, argument_class, _argument_instance|
      flags = argument_class[:flags]
      if (flags & Vips::ARGUMENT_INPUT) != 0  # We only want "input" arguments
        # …and we also only want optional non-deprecated arguments.
        if (flags & Vips::ARGUMENT_REQUIRED) == 0 && (flags & Vips::ARGUMENT_DEPRECATED) == 0
          # ParameterSpec name will be a String e.g. 'Q' or 'interlace' or 'page-height'
          element = param_spec[:name].to_sym
          g_type = GObject::g_type_name(param_spec[:value_type]).to_sym

          # There's only one thing I want to alias here right now,
          # so just do it as a one-off:
          isotopes = Set[element]
          isotopes.add(:quality) if element == :Q

          # Keyword arguments to splat into our Compound
          attributes = {
            :blurb => GObject::g_param_spec_get_blurb(param_spec),
            :default => self::vips_get_option_default(param_spec[:value_type]),
          }
          if G_TYPE_VALUES.has_key?(g_type)
            attributes[:valid] = G_TYPE_VALUES[g_type]
          end

          # Add the Compound for every alias
          compound = Cooltrainer::Compound.new(isotopes, **attributes)
          isotopes.each{ |isotope|
            options.store(isotope, compound)
          }
        end
      end
    }
    options
  end


  # Returns the default value for any ruby-vips GObject::GValue
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
  def self.vips_get_option_default(gtype)
    begin
      gtype_id = gtype.is_a?(String) ? GObject::g_type_from_name(gtype) : gtype
      # Deallocation is automatic when `gvp` goes out of scope.
      gvp = GObject::GValue.alloc
      gvp.init(gtype)
      gvp.get
    rescue FFI::NullPointerError => e
      # This is happening for VipsArrayDouble gtype 94691056795136
      # end I don't feel like debugging it rn lololol
      nil
    end
  end

end
