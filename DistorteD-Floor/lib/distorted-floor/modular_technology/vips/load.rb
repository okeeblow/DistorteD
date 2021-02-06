
require 'set'

require 'distorted/checking_you_out'
require 'distorted/modular_technology/vips/operation'
require 'distorted/modular_technology/vips/save'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::Vips::Load

  # Returns a Set of MIME::Types based on libvips LipsForeignLoad capabilities.
  # NOTE: libvips only declares support (via :get_suffixes) for the "saver" types,
  #   but libvips can use additional external libraries for wider media-types support, e.g.:
  #
  # - SVG with librsvg2★ / libcairo. [*]
  # - PDF with PDFium if available, otherwise with libpoppler-glib / libcairo.
  # - OpenEXR/libIlmImf — ILM high dynamic range image format.
  # - maybe more: https://github.com/libvips/libvips/blob/master/configure.ac
  #
  #   [FITS]: https://heasarc.gsfc.nasa.gov/docs/heasarc/fits.html
  #
  #   [RSVG2]: This is the normal SVG library for the GNOME/GLib world and is
  #            probably fine for 95% of use-cases, but I'm pissed off at it because of:
  #
  #            - https://gitlab.gnome.org/GNOME/librsvg/-/issues/56
  #            - https://gitlab.gnome.org/GNOME/librsvg/-/issues/100
  #            - https://gitlab.gnome.org/GNOME/librsvg/-/issues/183
  #            - https://gitlab.gnome.org/GNOME/librsvg/-/issues/494
  #            - https://bugzilla.gnome.org/show_bug.cgi?id=666477
  #            - https://phabricator.wikimedia.org/T35245
  #
  #            TLDR: SVG <tspan> elements' [:x, :y, :dy, :dx] attributes can be
  #            a space-delimited list of position values for individual
  #            characters in the <tspan>, but librsvg2 only supported reading
  #            those attributes as a single one-shot numeric value.
  #            Documents using this totally-common and totally-in-spec feature
  #            rendered incorrectly with librsvg2. Effected <tspan> elements'
  #            subsequent children would hug one edge of the rendered output.
  #
  #            And wouldn't you know it but the one (1) SVG on my website
  #            at the time I built this feature (IIDX-Turntable-parts.svg) used
  #            this feature for the double-digit parts diagram labels.
  #            I ended up having to edit my input document to just squash the
  #            offending <tspan>s down to a single child each.
  #            I guess that's semantically more correct in my document since they are
  #            numbers like Eleven and not two separate characters like '1 1'
  #            but still ugh lol
  #
  #            This was finally fixed in 2019 as of librsvg2 version 2.45.91 :)
  #            https://gitlab.gnome.org/GNOME/librsvg/-/issues/494#note_579774
  #
  #   [MAGICK]: The Magick-based '.bmp' loader is broken/missing in libvips <= 8.9.1,
  #            but our automatic Loader detection will handle that. Just FYI :)
  #

  # Vips::vips_foreign_find_save is based on filename suffix (extension),
  # but :vips_foreign_find_load seems to be based on file magic.
  # That is, we can't `vips_foreign_find_load` for a made-up filename
  # or plain suffix like we can to to build 'vips/save'::OUTER_LIMITS.
  # This caught me off guard but doesn't *entirely* not-make-sense,
  # considering Vips::Image::new_from_filename calls :vips_foreign_find_load
  # and obviously expects a file to be present.
  #
  ## Example — works with real file and fails with only suffix:
  # irb> Vips::vips_foreign_find_load '/home/okeeblow/cover.jpg'
  # => "VipsForeignLoadJpegFile"
  # irb> Vips::vips_foreign_find_load 'cover.jpg'
  # => nil
  #
  ## Syscalls of successful real-file :vips_foreign_find_load call
  # showing how it works:
  # [okeeblow@emi#okeeblow] strace ruby -e "require 'vips'; Vips::vips_foreign_find_load '/home/okeeblow/cover.jpg'" 2>&1|grep cover.jpg
  # access("/home/okeeblow/cover.jpg", R_OK) = 0
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY) = 5
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY) = 5
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY) = 5
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY) = 5
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY|O_CLOEXEC) = 5
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY|O_CLOEXEC) = 5
  # lstat("/home/okeeblow/cover.jpg", {st_mode=S_IFREG|0740, st_size=6242228, ...}) = 0
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY|O_CLOEXEC) = 5
  # stat("/home/okeeblow/cover.jpg", {st_mode=S_IFREG|0740, st_size=6242228, ...}) = 0
  # stat("/home/okeeblow/cover.jpg-journal", 0x7fffa70f4df0) = -1 ENOENT (No such file or directory)
  # stat("/home/okeeblow/cover.jpg-wal", 0x7fffa70f4df0) = -1 ENOENT (No such file or directory)
  # stat("/home/okeeblow/cover.jpg", {st_mode=S_IFREG|0740, st_size=6242228, ...}) = 0
  # openat(AT_FDCWD, "/home/okeeblow/cover.jpg", O_RDONLY) = 5
  #
  ## …and of a fake suffix-only filename to show how it doesn't:
  # [okeeblow@emi#okeeblow] strace ruby -e "require 'vips'; Vips::vips_foreign_find_load 'fartbutt.jpg'" 2>&1|grep '.jpg'
  # read(5, ".write_to_target target, \".jpg[Q"..., 8192) = 8192
  # access("fartbutt.jpg", R_OK)            = -1 ENOENT (No such file or directory)
  #
  ## Versus the corresponding Vips::vips_foreign_find_save which is *only* based
  # on filename suffix and does not try to look at a file at all,
  # perhaps (read: obviously) because that file wouldn't exist yet to test until we save it :)
  # [okeeblow@emi#okeeblow] strace ruby -e "require 'vips'; p Vips::vips_foreign_find_save 'fartbutt.jpg'" 2>&1|grep -E 'Save|.jpg'
  # read(5, ".write_to_target target, \".jpg[Q"..., 8192) = 8192
  # write(1, "\"VipsForeignSaveJpegFile\"\n", 26"VipsForeignSaveJpegFile"
  #
  # For this reason I'm going to write my own shim Loader-finder and use it instead.
  LOWER_WORLD = Cooltrainer::DistorteD::Technology::Vips::VipsType::loader_types.keep_if { |type, operations|
    # Skip text types for image data until I have a way for multiple
    # type-supporting Molecules to vote on a src file.
    # TODO: Support loading image CSV
    # TODO: Make this more robust/automatic.
    Array[
      type.media_type != 'application'.freeze,  # e.g. application/pdf
      type.media_type != 'text'.freeze,  # e.g. text/csv
    ].all? && Array[
      type.sub_type.include?('zip'.freeze),
      # Skip declaring SVG here since I want to handle it in a Vector-only Molecule
      # and will re-declare this there. Prolly need to think up a better way to do this.
      type.sub_type.include?('svg'.freeze),
    ].none?
  }.transform_values { |v| v.map(&:options).reduce(&:merge) }


  self::LOWER_WORLD.each_key { |t|
    define_method(t.distorted_open_method) { |src_path = path, change|
      # Find a VipsType Struct for the saver operation
      vips_operation = Cooltrainer::DistorteD::Technology::Vips::VipsType::loader_for(t).first

      # Prepare a Hash of options appropriate for this operation.
      # We explicitly declare all supported VipsArguments, using the FFI-detected
      # default values for keys with no user-given value.
      options = change.to_hash.slice(
        # Get an Array[Symbol] of non-aliased option keys.
        # Loading any aliases' values happens when the Change/Atoms are constructed.
        *vips_operation.options.keep_if { |aka, compound| aka == compound.element }.keys
      ).reject { |k,v| v.nil? }.transform_keys { |k|
        # The `ruby-vips` binding expects hyphenated argument names to be converted to underscores:
        # https://github.com/libvips/ruby-vips/blob/4f696e30796adcc99cbc70ff7fd778439f0cbac7/lib/vips/operation.rb#L78-L80
        k.to_s.gsub('-', '_').to_sym
      }

      # Do the thing.
      Vips::Operation.call(
        # `:vips_call` expects the operation_name to be a String:
        # https://libvips.github.io/libvips/API/current/VipsOperation.html#vips-call
        vips_operation.name.to_s,
        # Loaders only take the source path as a required argument.
        [src_path],
        # Operation-appropriate options Hash
        options,
        # `:options_string`, unused since we have everything in our Hash.
        ''.freeze,
      )
    }
  }


  # Returns a Vips::Image from a file source.
  # TODO: Get rid of this method! This is an old entrypoint.
  #       Consume lower Types as a Change once we support Change chaining, then execute a chain.
  def to_vips_image(change = nil)
    @vips_image ||= begin
      lower_config = the_setting_sun(:lower_world, *(type_mars.first&.settings_paths)) || Hash.new
      atoms = Hash.new
      lower_world[type_mars.first].values.reduce(&:concat).each_pair { |aka, compound|
        next if aka != compound.element  # Skip alias Compounds since they will all be handled at once.
        atoms.store(compound.element, Cooltrainer::Atom.new(compound.isotopes.reduce(nil) { |value, isotope|
          value || lower_config.fetch(isotope, nil) || context_arguments&.fetch(isotope, nil)
        }, compound.default))
      }
      self.send(type_mars.first.distorted_open_method, **atoms.transform_values(&:get))
    end
  end


end
