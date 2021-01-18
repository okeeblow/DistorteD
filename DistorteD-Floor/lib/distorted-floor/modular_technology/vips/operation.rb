require 'distorted/modular_technology/vips/ffi'

require 'distorted/checking_you_out'
require 'distorted/element_of_media'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::Vips


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
    :gboolean => [false, true],
    :gchararray => String,
    :gdouble => Float,
    :gint => Integer,
  }

  # Aliases we want to support for consistency and accessibility.
  VIPS_ALIASES = {
    :Q => Set[:Q, :quality],
    :colours => Set[:colours, :colors],
    :centre => Set[:centre, :center],  # America; FUCK YEAH!
  }

  # GEnum valid values are detectable, but I don't know how to do the same
  # for the numeric parameters. Specify them here manually for now.
  VIPS_VALID = {
    :"page-height" => (0..Vips::MAX_COORD),
    :"quant-table" => (0..8),
    :Q => (0..100),
    :colours => (2..256),
    :dither => (0.0..1.0),
    :compression => (0..9),
    :"alpha-q" => (0..100),
    :"reduction-effort" => (0..6),
    :kmin => (0..0x7FFFFFFF),  # https://en.wikipedia.org/wiki/2,147,483,647
    :kmax => (0..0x7FFFFFFF),
    :"tile-width" => (0..0x8000),  # 32768
    :"tile-height" => (0..0x8000),
    :xres => (0.001..1e+06),
    :yres => (0.001..1e+06),
  }

  # Same with default values for numeric parameters.
  VIPS_DEFAULT = {
    :Q => 75,
    :colours => 256,
    :compression => 6,
    :"alpha-q" => 100,
    :"reduction-effort" => 4,
    :kmin => 0x7FFFFFFF - 1,
    :kmax => 0x7FFFFFFF,
    :"tile-width" => 128,
    :"tile-height" => 128,
    :xres => 1,
    :yres => 1,
  }


  # Store FFI results where possible to minimize memory churn 'n' general fragility.
  @@vips_foreign_types = Hash[]
  @@vips_foreign_suffixes = Hash[]
  @@vips_foreign_options = Hash[]


  def self.vips_foreign_find_loader_by_suffix(filename)
    self.vips_foreign_find_class_by_suffix(filename, self::TOP_LEVEL_LOADER)
  end
  def self.vips_foreign_find_saver_by_suffix(filename)
    self.vips_foreign_find_class_by_suffix(filename, self::TOP_LEVEL_SAVER)
  end

  # Returns a Set of MIME::Types based on the "supported suffix" lists generated
  # by libvips and our other functions here in this Module.
  def self.vips_get_types(basename)
    @@vips_foreign_types[basename.to_sym] ||= self::vips_get_suffixes(basename).each_with_object(Set[]) { |suffix, types|
      types.merge(CHECKING::YOU::OUT(suffix))
    }
  end


  # Returns a Set of String filename suffixes supported by a tree of libvips loader/saver classes.
  #
  # The Array returned from self::vips_get_suffixes_per_nickname will be overloaded
  # with all duplicate suffix possibilities for each Type according to libvips.
  #   e.g.  ['.jpg', '.jpe', '.jpeg', '.png], '.gif', '.tif', '.tiff' … ]
  def self.vips_get_suffixes(basename)
    @@vips_foreign_suffixes[basename.to_sym] ||= self::vips_get_suffixes_per_nickname(basename).values.each_with_object(Set[]) {|s,n| n.merge(s)}
  end


  # Returns a Hash[alias] of Compound attributes supported by a given libvips Loader/Saver class.
  def self.vips_get_options(nickname)
    return Hash if nickname.nil?
    @@vips_foreign_options[nickname.to_sym] ||= self::vips_get_nickname_options(nickname)
  end


  protected


  # Returns a String libvips Loader class name most appropriate for the given filename suffix.
  # This is a workaround for the fact that the built-in Vips::vips_foreign_find_load
  # requires access of a real image file, and we are here talking only of hypothetical ones.
  # See this method's call site in 'vips/load' for more detailed comments on this.
  #
  # irb(main):234:0> Vips::vips_filename_get_filename('fart.jpg')
  # => #<FFI::Pointer address=0x0000561efe3d08e0>
  # irb(main):235:0> Vips::p2str(Vips::vips_filename_get_filename('fart.jpg'))
  # => "fart.jpg"
  # irb(main):236:0> File.extname(Vips::p2str(Vips::vips_filename_get_filename('fart.jpg')))
  # => ".jpg"
  # irb(main):237:0> Vips::vips_foreign_find_save(File.extname(Vips::p2str(Vips::vips_filename_get_filename('fart.jpg'))))
  # => "VipsForeignSaveJpegFile"
  #
  # Here are the available Operations I have on my laptop with libvips 8.8:
  # [okeeblow@emi#okeeblow] vips -l|grep VipsForeign|grep File
  #   VipsForeignLoadPdfFile (pdfload), load PDF with libpoppler (.pdf), priority=0, is_a, get_flags, get_flags_filename, header, load
  #   VipsForeignLoadSvgFile (svgload), load SVG with rsvg (.svg, .svgz, .svg.gz), priority=0, is_a, get_flags, get_flags_filename, header, load
  #   VipsForeignLoadGifFile (gifload), load GIF with giflib (.gif), priority=0, is_a, get_flags, get_flags_filename, header, load
  #   VipsForeignLoadJpegFile (jpegload), load jpeg from file (.jpg, .jpeg, .jpe), priority=50, is_a, get_flags, header, load
  #   VipsForeignLoadWebpFile (webpload), load webp from file (.webp), priority=0, is_a, get_flags, get_flags_filename, header, load
  #   VipsForeignLoadTiffFile (tiffload), load tiff from file (.tif, .tiff), priority=50, is_a, get_flags, get_flags_filename, header, load
  #   VipsForeignLoadMagickFile (magickload), load file with ImageMagick, priority=-100, is_a, get_flags, get_flags_filename, header
  #   VipsForeignSaveRadFile (radsave), save image to Radiance file (.hdr), priority=0, rgb
  #   VipsForeignSaveDzFile (dzsave), save image to deepzoom file (.dz), priority=0, any
  #   VipsForeignSavePngFile (pngsave), save image to png file (.png), priority=0, rgba
  #   VipsForeignSaveJpegFile (jpegsave), save image to jpeg file (.jpg, .jpeg, .jpe), priority=0, rgb-cmyk
  #   VipsForeignSaveWebpFile (webpsave), save image to webp file (.webp), priority=0, rgba-only
  #   VipsForeignSaveTiffFile (tiffsave), save image to tiff file (.tif, .tiff), priority=0, any
  #   VipsForeignSaveMagickFile (magicksave), save file with ImageMagick (.gif, .bmp), priority=-100, any
  #
  # You can notice differences such as a `dzsave` and `radsave` but no `dzload` or `radload`.
  # This is why we can't assume that HAS_SAVER == HAS_LOADER across the board.
  # Other differences are invisible here, like different formats supported silently by `magickload`,
  # so that Operation is the catch-all fallback if we don't have any better idea.
  #
  # We can try taking a MIME::Type's `sub_type`, capitalizing it, and trying to find a Loader Operation by that name.
  # irb(main):254:0> MIME::Types::type_for('.heif').last.sub_type.capitalize
  # => "Heif"
  # irb(main):255:0> MIME::Types::type_for('.jpg').last.sub_type.capitalize
  # => "Jpeg"
  #
  ## NOTE: I'm writing this on an old install that lacks HEIF support in its libvips 8.8 installation,
  # so this failure to find 'VipsForeignLoadHeifFile' is expected and correct for me!
  # It probably won't fail for you in the future, but I want to make sure to include
  # some example of varying library capability and not assume capabilities based on libvips version:
  #
  # irb(main):257:0> GObject::g_type_from_name("VipsForeignLoad#{MIME::Types::type_for('.jpg').last.sub_type.capitalize}File")
  # => 94691057380176
  # irb(main):258:0> GObject::g_type_from_name("VipsForeignLoad#{MIME::Types::type_for('.heif').last.sub_type.capitalize}File")
  # => 0
  def self.vips_foreign_find_class_by_suffix(filename, top_level)
    # VIPS' `get_filename` is meant to strip the hash-delimited arguments from vips CLI arguments and returns a pointer,
    # and :p2str turns that back into a String. We really don't need either of those calls for our usage,
    # but I'm going to do it anyway to be as consistent with ruby-vips' built-in methods as possible.
    vips_filename = Vips::p2str(Vips::vips_filename_get_filename(filename))
    # File.extname will return an empty String when we supply just a `.extension`-style String.
    # Since we must take full filename arguments as well as just-extension arguments,
    # just pass the fill filename to CYO:
    # https://bugs.ruby-lang.org/issues/15244
    guessed_loader = "#{top_level}#{CHECKING::YOU::OUT(vips_filename).first.sub_type.capitalize}File"
    return FFI::vips_object_valid?(guessed_loader) ? guessed_loader : "#{top_level}MagickFile"
  end

  # Returns a Set of local MIME::Types supported by the given class and any of its children.
  def self.vips_get_types_per_nickname(basename)
    self::vips_get_suffixes_per_nickname(basename).transform_values(&CHECKING::YOU.method(:OUT))
  end

  # Returns a Hash[Type] of Set[String] class nicknames supporting that Type.
  def self.vips_get_nicknames_per_type(basename)
    self::vips_get_nickname_types(basename).each_with_object(Hash.new { |h,k| h[k] = Set[] }) { |(nickname,type_set), memo|
      type_set.each{ |t|
        memo[t] << nickname
      }
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
    self::vips_get_child_class_nicknames(basename).each_with_object(Hash.new) { |nickname, nickname_suffixes|
      # "Search below basename, return the first class whose name or nickname matches."
      # VipsForeign is a basename for savers and loaders alike.
      foreign_class = Vips::vips_class_find('VipsForeign'.freeze, nickname)
      next if foreign_class.null?

      # Construct a buffer to hold the String summary of a VipsObject
      # so we can parse the file extensions out of it.
      # These are one-line Strings so 2048 bytes should be a safe size.
      # For example, every Foreign Jpeg Loader and Saver subclass description
      # comes in at under 800 bytes on my system, and we will only ever look
      # at one of these lines at a time in this method:
      #
      # [okeeblow@emi#DistorteD-Booth] vips -l|grep Jpeg
      #  VipsForeignLoadJpeg (jpegload_base), load jpeg, priority=0
      #    VipsForeignLoadJpegFile (jpegload), load jpeg from file (.jpg, .jpeg, .jpe), priority=50, is_a, get_flags, header, load
      #    VipsForeignLoadJpegBuffer (jpegload_buffer), load jpeg from buffer, priority=0, is_a_buffer, get_flags, header, load
      #  VipsForeignSaveJpeg (jpegsave_base), save jpeg (.jpg, .jpeg, .jpe), priority=0, rgb-cmyk
      #    VipsForeignSaveJpegFile (jpegsave), save image to jpeg file (.jpg, .jpeg, .jpe), priority=0, rgb-cmyk
      #    VipsForeignSaveJpegBuffer (jpegsave_buffer), save image to jpeg buffer (.jpg, .jpeg, .jpe), priority=0, rgb-cmyk
      #    VipsForeignSaveJpegMime (jpegsave_mime), save image to jpeg mime (.jpg, .jpeg, .jpe), priority=0, rgb-cmyk
      # [okeeblow@emi#DistorteD-Booth] vips -l|grep Jpeg|wc
      # 7      75     773
      buf_struct = Vips::BufStruct.new
      buf_struct_string = ::FFI::MemoryPointer.new(:char, 2048)
      buf_struct[:base] = buf_struct_string
      buf_struct[:mx] = 2048
      Vips::vips_object_summary_class(foreign_class, buf_struct.pointer)
      class_summary = buf_struct_string.read_string

      # Parse an Array[String] of file extensions out of a class summary.
      suffixes = class_summary.scan(/\.\w+\.?\w+/)
      nickname_suffixes.update({nickname => suffixes.to_set}) unless suffixes.empty?
    }
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
    generate_class.call(GObject::g_type_from_name(basename.to_s))
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

          # `magicksave` takes an argument `format` to choose one of its many supported types,
          # but that selection in DistorteD-land is via our MIME::Types, so this option should be dropped.
          # https://github.com/libvips/libvips/blob/4de9b56725862edf872ae503a3dfb4cf05da9e77/libvips/foreign/magicksave.c#L455~L460
          next if element == :format

          # GObject::g_type_name will return `nil` for an invalid :value_type,
          # but these are coming straight from libvips so we know they're fine.
          gtype_name = GObject::g_type_name(param_spec[:value_type]).to_sym

          # Support aliasing options like 'Q' into 'quality' for consistency
          # and 'colours' into 'colors' for accessibility.
          isotopes = VIPS_ALIASES.dig(element) || Set[element]

          # Keyword arguments to splat into our Compound
          attributes = {
            # Some libvips drivers seem to have mixed-leading-case options,
            # like ppmsave and webp save for example:
            # https://github.com/libvips/libvips/blob/4de9b56725862edf872ae503a3dfb4cf05da9e77/libvips/foreign/ppmsave.c#L396~L415
            # https://github.com/libvips/libvips/blob/4de9b56725862edf872ae503a3dfb4cf05da9e77/libvips/foreign/webpsave.c#L152
            # TODO: Inventory all of these and submit an upstream patch to capitaqlize them consistently.
            # Until them (and for old versions), fix up the first letter manually.
            # Avoid using just `blurb.capitalize` as that will lowercase everything after
            # the first character, which is definitely worse than what I'm trying to fix lol
            :blurb => GObject::g_param_spec_get_blurb(param_spec).tap{|blurb| blurb[0] = blurb[0].capitalize},
            :default => FFI::vips_get_option_default(param_spec[:value_type]),
          }
          if GObject::g_type_fundamental(param_spec[:value_type]) == GObject::GENUM_TYPE
            attributes[:valid] = self::vips_get_enum_values(param_spec[:value_type])
          elsif VIPS_VALID.has_key?(element)
            attributes[:valid] = VIPS_VALID[element]
          elsif G_TYPE_VALUES.has_key?(gtype_name)
            attributes[:valid] = G_TYPE_VALUES[gtype_name]
          end

          # Add the Compound for every alias
          compound = Cooltrainer::Compound.new(isotopes, **attributes)
          isotopes.each{ |isotope|
            options.store(isotope, compound)
          }
        end
      end
    }

    # This isn't really a 'Saver' Option — rather an argument to a separate
    # :smartcrop or :thumbnail VIPS method we can call, but I want to offer
    # this option on every Type and use it to control the method we call
    # to write the image.
    options.store(:crop, Cooltrainer::Compound.new(:crop,
      blurb: 'Visual cropping method',
      valid: self::vips_get_enum_values('VipsInteresting'.freeze),
      default: FFI::vips_get_option_default('VipsInteresting'.freeze),
    )) if nickname.include?('Save'.freeze)  # Only for savers!!

    # All done :)
    options
  end


  # Returns a Set[Symbol] of supported enum values for a given g_type
  def self.vips_get_enum_values(gtype)
    begin
      gtype_id = gtype.is_a?(String) ? GObject::g_type_from_name(gtype) : gtype

      # HACK HACK HACK:
      # There *has* to be a better/native way to get this, but for now I'm just going to
      # parse them out of the error message you can access after trying an obviously-wrong value.
      #
      # irb> Vips::vips_error_clear
      # => nil
      # irb> GObject::g_type_from_name 'VipsForeignTiffCompression'
      # => 94691059614768
      # irb> Vips::vips_enum_from_nick 'DistorteD', 94691059614768, 'lolol'
      # => -1
      # irb> Vips::vips_error_buffer
      # => "DistorteD: enum 'VipsForeignTiffCompression' has no member 'lolol', should be one of: none, jpeg, deflate, packbits, ccittfax4, lzw\n"
      Vips::vips_enum_from_nick('DistorteD'.freeze, gtype_id, 'lolol'.freeze)
      error_buffer = Vips::vips_error_buffer
      if error_buffer.include?('should be one of: '.freeze)
        Vips::vips_error_clear
        # Parse the error into a Set of Symbol options
        discovered = error_buffer.split('should be one of: '.freeze)[1][0..-2].split(', '.freeze).map(&:to_sym).to_set
        # For any Options with aliases, merge in the aliases.
        (discovered & self::VIPS_ALIASES.keys.to_set).each { |aliased|
          discovered.merge(self::VIPS_ALIASES[aliased])
        }
        # We need to give this back as an Array because callers will want to call :join on it,
        # and we should give it back sorted so aliased aren't all piled up at the end.
        discovered.to_a.sort
      else
        return Array[]
      end
    rescue
      return Array[]
    end
  end

end
