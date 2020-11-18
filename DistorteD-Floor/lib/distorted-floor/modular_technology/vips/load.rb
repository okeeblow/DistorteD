
require 'set'

require 'distorted/checking_you_out'
require 'distorted/modular_technology/vips_foreign'
require 'distorted/modular_technology/vips_save'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Technology; end
module Cooltrainer::DistorteD::Technology::VipsLoad

  include Cooltrainer::DistorteD::Technology::VipsForeign

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

  # NOTE: The Magick-based '.bmp' loader is broken/missing in libvips <= 8.9.1:
  VIPS_LOADERS = Cooltrainer::DistorteD::Technology::VipsForeign::vips_get_types('VipsForeignLoad').keep_if { |t|
    t.media_type != 'text'.freeze and not t.sub_type.include?('zip'.freeze)
  }

  LOWER_WORLD = VIPS_LOADERS.reduce(Hash[]) { |types,type|
    types[type] = Cooltrainer::DistorteD::Technology::VipsForeign::vips_get_options(
      Vips::vips_foreign_find_load(".#{type.preferred_extension}")
    )
    types
  }


  def to_vips_image
    # TODO: Learn more about what VipsAccess means for our use case,
    # if the default should be changed, and if it should be
    # a user-controllable attr or not.
    # https://libvips.github.io/libvips/API/current/VipsImage.html#VipsAccess
    # https://libvips.github.io/libvips/API/current/How-it-opens-files.md.html
    @vips_image ||= Vips::Image.new_from_file(path)
  end


end
