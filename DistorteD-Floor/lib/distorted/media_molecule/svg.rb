require 'set'

require 'svg_optimizer'  # https://github.com/fnando/svg_optimizer

require 'distorted/checking_you_out'
require 'distorted/modular_technology/vips/save'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::SVG


  #WISHLIST: Support VML for old IE compatibility.
  #  Example: RaphaëlJS — https://en.wikipedia.org/wiki/Rapha%C3%ABl_(JavaScript_library)
  LOWER_TYPES = Set[
    CHECKING::YOU::OUT['image/svg+xml']
  ]
  LOWER_WORLD = LOWER_TYPES.reduce(Hash[]) { |types,type|
    types[type] = Cooltrainer::DistorteD::Technology::Vips::vips_get_options(
      Cooltrainer::DistorteD::Technology::Vips::vips_foreign_find_load_suffix(".#{type.preferred_extension}")
    ).merge(Hash[
      :optimize => Cooltrainer::Compound.new(:optimize, valid: Cooltrainer::BOOLEAN_VALUES, default: false, blurb: 'SvgOptimizer'),
      :unlimited => Cooltrainer::Compound.new(:unlimited, valid: Cooltrainer::BOOLEAN_VALUES, default: true, blurb: 'Load SVGs larger than 10MiB (security feature)'),
    ])
    types
  }
  include Cooltrainer::DistorteD::Technology::Vips::Save


  def to_vips_image
    # TODO: Load-time options for various formats, like SVG's `unlimited`:
    # "SVGs larger than 10MB are normally blocked for security. Set unlimited to allow SVGs of any size."
    # https://libvips.github.io/libvips/API/current/VipsForeignSave.html#vips-svgload
    @vips_image ||= Vips::Image.new_from_file(path)
  end

  define_method(CHECKING::YOU::OUT['image/svg+xml'].distorted_method) { |dest, *a, **k, &b|
    if k.dig(:optimize)
      SvgOptimizer.optimize_file(path, dest, SvgOptimizer::DEFAULT_PLUGINS)
    else
      copy_file(dest, *a, **k, &b)
    end
  }

end
