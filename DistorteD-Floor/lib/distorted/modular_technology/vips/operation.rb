require 'set'
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
  TOP_LEVEL_FOREIGN = :VipsForeign
  TOP_LEVEL_LOADER  = :VipsForeignLoad
  TOP_LEVEL_SAVER   = :VipsForeignSave


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


  # Encapsulate any VipsObject descendant based on GType ID or name
  VipsType = Struct.new(:id) do
    def initialize(id_or_name)
      super(id_or_name.is_a?(Integer) ? id_or_name : GObject::g_type_from_name(id_or_name.to_s))
    end
    def name; GObject::g_type_name(self.id); end
    def to_s; self.name.to_s; end
    def to_sym; self.name.to_sym; end
    def nickname; Vips::nickname_find(self.id); end
    def inspect; "#<#{self.name}>"; end

    # Returns an Array[String] of VipsForeign suffixes.
    #
    # Suffixes are defined in a NULL-terminated C Array in each VIPS class:
    # https://github.com/libvips/libvips/search?p=3&q=suffs%5B%5D
    # It's kinda silly but the best way to discover these is parse them
    # out of the single-line String descriptions as seen in `vips -l`.
    def suffixes
      @suffixes ||= begin
        # vips_class_find returns an FFI::Pointer, and we can use our own class name as the first param:
        # irb> Vips::vips_class_find('VipsForeignSaveJpegFile', 'jpegsave')
        # => #<FFI::Pointer address=0x00005592a24bac40>
        vips_class_pointer = Vips::vips_class_find(TOP_LEVEL_FOREIGN.to_s, nickname)
        return Array.new if vips_class_pointer.null?
        # 2K buffer should always be big enough to read single-line Strings like these:
        # VipsForeignLoadJpegFile (jpegload), load jpeg from file (.jpg, .jpeg, .jpe), priority=50, is_a, get_flags, header, load
        buf_struct = Vips::BufStruct.new
        buf_struct_string = ::FFI::MemoryPointer.new(:char, 2048)
        buf_struct[:base] = buf_struct_string
        buf_struct[:mx] = 2048
        Vips::vips_object_summary_class(vips_class_pointer, buf_struct.pointer)
        class_summary = buf_struct_string.read_string

        # Parse an Array[String] of file extensions out of a class summary.
        class_summary.scan(/\.\w+\.?\w+/)
      end
    end  # suffixes

    # Returns a Hash[aka] => Compound based on this VipsType's VipsArguments.
    def options
      @options ||= Hash.new.tap { |options|
        # `:vips_argument_map` itself will return void/nil, so we need to give it a function that modifies an existing Hash.
        Vips::vips_argument_map(
          # `:vips_operation_new` takes a String argument of the nickname, not the fullname:
          # https://libvips.github.io/libvips/API/current/VipsOperation.html#vips-operation-new
          Vips::vips_operation_new(self.nickname),
          # `:vips_argument_map`'s second argument is a VipsArgumentMapFn to call for each VipsArgument:
          # https://libvips.github.io/libvips/API/current/VipsObject.html#VipsArgumentMapFn
          Proc.new { |_vips_object, param_spec, argument_class, _argument_instance|
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

                Cooltrainer::Compound.new(
                  # Support aliasing options like 'Q' into 'quality' for consistency
                  # and 'colours' into 'colors' for accessibility.
                  VIPS_ALIASES.dig(element) || Set[element],
                  # Some libvips drivers seem to have mixed-leading-case options,
                  # like ppmsave and webp save for example:
                  # https://github.com/libvips/libvips/blob/4de9b56725862edf872ae503a3dfb4cf05da9e77/libvips/foreign/ppmsave.c#L396~L415
                  # https://github.com/libvips/libvips/blob/4de9b56725862edf872ae503a3dfb4cf05da9e77/libvips/foreign/webpsave.c#L152
                  blurb: GObject::g_param_spec_get_blurb(param_spec).tap { |blurb| blurb[0] = blurb[0].capitalize },
                  default: self.class.get_argument_default(param_spec),
                  valid: self.class.get_argument_valid_values(param_spec),
                ).tap { |compound|
                  # Add the Compound for every alias
                  compound.isotopes.each{ |isotope| options.store(isotope, compound) }
                }
              end
            end

            # This isn't really a 'Saver' Option — rather an argument to a separate
            # :smartcrop or :thumbnail VIPS method we can call, but I want to offer
            # this option on every Type and use it to control the method we call
            # to write the image.
            # TODO: Handle VipsThumbnailImage's (and other Operations') full `:options` and remove this one-off.
            #       This is here as a temporary shim for feature parity during refactoring.
            # TODO: VipsType#parent method so we can check upward for :VipsForeign heritage.
            if self.name.include?('Foreign'.freeze) and self.name.include?('Save'.freeze)
              options.store(:crop, self.class.new(:VipsThumbnailImage).options.fetch(:crop, nil))
            end
          },
          nil,  # `:a` "Client data"
          nil,  # `:b` "Client data"
        )
      }
    end

    # Returns a Set[MIME::Type] based on our suffixes.
    def types
      @types ||= begin
        # We will likely get duplicate suffixes for a single MIME::Type, but we may also get suffixes for multiple Types:
        # irb> Cooltrainer::DistorteD::Technology::Vips::FFI::VipsType.new('VipsForeignSaveJpegFile').suffixes
        # => [".jpg", ".jpeg", ".jpe"]
        # irb> Cooltrainer::DistorteD::Technology::Vips::FFI::VipsType.new('VipsForeignSaveMagickFile').suffixes
        # => [".gif", ".bmp"]
        self.suffixes&.map(&CHECKING::YOU::method(:OUT))&.reduce(:merge)
      end
    end  # types

    # Returns an Array[VipsType] of our direct children.
    def children
      # https://libvips.github.io/libvips/API/current/VipsObject.html#vips-type-map
      # "Map over a type's children. Stop when fn returns non-nil and return that value."
      child_ids = Array.new
      # vips_type_map will return an FFI::Pointer, so we can't return it directly.
      Vips::vips_type_map(self.id, child_ids.method(:append).to_proc, nil)
      # Calling :append in :vips_type_map will append a g_type as well as a FFI::Pointer to 0x0,
      # so filter the pointers out (Interger g_types only), then turn it each child
      # into another Hash of it to its children.
      child_ids.select { |c| c.is_a?(Integer) }.map(&self.class.method(:new))
    end

    # Returns a Hash[self] => Array[VipsType/Hash] of our children and all of their childrens' children.
    # Array members will be another Hash[child] => Array[grandchildren] if our children
    # have any children, or just the child VipsType if it doesn't.
    def family_tree
      # Return only ourselves as a value instead of another empty Hash if we have no children.
      children.empty? ? self : Hash[self => children.map(&:family_tree)]
    end

    # Returns an Array[VipsType] of all of our children and all of their children and
    def family_reunion
      self.children.each_with_object(Array[self]) { |child, family|
        family.push(*child.family_reunion)
      }
    end

    # Returns an Array[VipsType] of loaders/savers given a filename, suffix, or MIME::Type.
    def self.loader_for(given); self.foreign_for(TOP_LEVEL_LOADER, given); end
    def self.saver_for(given);  self.foreign_for(TOP_LEVEL_SAVER,  given); end

    # Returns a Hash[MIME::Type] => Set[VipsType] of loaders/savers.
    def self.loader_types; self.foreign_types(TOP_LEVEL_LOADER); end
    def self.saver_types;  self.foreign_types(TOP_LEVEL_SAVER);  end

    private

    # Helper method that returns an Array[VipsType] given a top-level VipsType and a filename, suffix, or MIME::Type.
    def self.foreign_for(top_level, given)
      search = case given
      when Array then given
      when MIME::Type then Array[given]
      when String then given.include?('/'.freeze) ? Array[CHECKING::YOU::OUT[given]] : CHECKING::YOU::OUT(given)
      end
      self.new(top_level).family_reunion.select { |vt| vt.types&.intersection(search)&.length&.method(:>)&.call(0) }
    end

    # Helper method that returns a Hash[MIME::Type] => Set[VipsType] given a top-level VipsType.
    def self.foreign_types(top_level)
      self.new(top_level).family_reunion.each_with_object(
        Hash.new { |h,k| h[k] = Set.new }
      ) { |operation, types|
        next if operation.types.nil?
        operation.types.each { |type| types[type].add(operation) }
      }
    end

    # Returns a default value (type variable) given a GParamSpec
    def self.get_argument_default(param_spec)
      begin
        default_pointer = GObject::g_param_spec_get_default_value(param_spec)
        default = GObject::GValue.new(default_pointer)
        return nil if default.null?
        return default.get
      rescue ::FFI::NullPointerError => npe
        # For some reason the :null? check doesn't catch NPEs from `get_array_of_float64`
        # which I think is the GBoxed GType like VipsArrayDouble
        nil
      end
    end

    # Returns a Range, Enumerable, Class, or other value constraint.
    def self.get_argument_valid_values(param_spec)
      # HACK: Define Ranges manually until I figure out how to introspect them.
      if VIPS_VALID.has_key?(param_spec[:name].to_sym)
        return VIPS_VALID[param_spec[:name].to_sym]
      end

      return case GObject::g_type_fundamental(param_spec[:value_type])
      when GObject::GENUM_TYPE
        # I think the """proper""" way to do this is with gobject-introspection,
        # but it's way simpler for now to just iterate until we find the terminating NULL.
        Set.new.tap { |values|
          loop.with_index { |_, i|
            value = Vips::vips_enum_nick(param_spec[:value_type], i)
            break if value == '(null)'.freeze or i > 33  # Safety factor in case the String ever differs
            values.add(value)
          }
        }.map(&:to_sym)  # TODO: Fix value aliasing
      when GObject::GBOOL_TYPE then Set[false, true]
      when GObject::GDOUBLE_TYPE then Float
      when GObject::GINT_TYPE then Integer
      when GObject::GUINT64_TYPE then Integer
      when GObject::GBOXED_TYPE then nil  #  TODO: Something besides nil
      else nil
      end
    end

  end  # VipsType Struct


end
