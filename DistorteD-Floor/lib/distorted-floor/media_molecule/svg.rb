require 'set'

require 'svg_optimizer'  # https://github.com/fnando/svg_optimizer

require 'distorted/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT
require 'distorted/modular_technology/vips/save'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::SVG

  include Cooltrainer::DistorteD::Technology::Vips::Save

  SVG_TYPE = ::CHECKING::YOU::OUT::from_ietf_media_type('image/svg+xml')

  LOWER_WORLD = Hash[
    SVG_TYPE => Cooltrainer::DistorteD::Technology::Vips::VipsType::loader_for(SVG_TYPE).map(&:options).reduce(&:merge)
  ].merge(Hash[
    :optimize => Cooltrainer::Compound.new(:optimize, valid: Cooltrainer::BOOLEAN_VALUES, default: false, blurb: 'SvgOptimizer'),
  ])

  # WISHLIST: Support VML for old IE compatibility.
  #  Example: RaphaëlJS — https://en.wikipedia.org/wiki/Rapha%C3%ABl_(JavaScript_library)
  OUTER_LIMITS = Hash[
    SVG_TYPE => nil,
  ]

  def to_vips_image(change = nil)
    # NOTE: libvips 8.9 added the `unlimited` argument to svgload.
    # Loading SVGs >= 10MiB in size will fail on older libvips.
    # https://github.com/libvips/libvips/commit/55e49831b801e05ddd974b1e2102fda7956c53f5
    @vips_image ||= Vips::Image.new_from_file(path)
  end

  define_method(SVG_TYPE.distorted_file_method) { |dest_root, change|
    if change.optimize
      SvgOptimizer.optimize_file(path, change.paths(dest_root).first, SvgOptimizer::DEFAULT_PLUGINS)
    else
      copy_file(change.paths(dest_root).first)
    end
  }

end
