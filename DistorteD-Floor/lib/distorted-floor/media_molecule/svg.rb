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
    ])
    types
  }
  include Cooltrainer::DistorteD::Technology::Vips::Save


  def to_vips_image
    # NOTE: libvips 8.9 added the `unlimited` argument to svgload.
    # Loading SVGs >= 10MiB in size will fail on older libvips.
    # https://github.com/libvips/libvips/commit/55e49831b801e05ddd974b1e2102fda7956c53f5
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
