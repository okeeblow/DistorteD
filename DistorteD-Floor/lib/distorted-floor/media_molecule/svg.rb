require 'set'

require 'svg_optimizer'

require 'distorted/checking_you_out'
require 'distorted/injection_of_love'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::SVG


  #WISHLIST: Support VML for old IE compatibility.
  #  Example: RaphaëlJS — https://en.wikipedia.org/wiki/Rapha%C3%ABl_(JavaScript_library)
  LOWER_WORLD = CHECKING::YOU::IN(/^image\/svg/)

  ATTRIBUTES = Set[
    :alt,
    :caption,
    :href,
    :loading,
    :optimize,
  ]
  ATTRIBUTES_VALUES = {
    :optimize => Cooltrainer::BOOLEAN_VALUES,
  }
  ATTRIBUTES_DEFAULT = {
    :optimize => false,
  }

  include Cooltrainer::DistorteD::Technology::VipsSave
  include Cooltrainer::DistorteD::InjectionOfLove

  def to_vips_image
    # TODO: Load-time options for various formats, like SVG's `unlimited`:
    # "SVGs larger than 10MB are normally blocked for security. Set unlimited to allow SVGs of any size."
    # https://libvips.github.io/libvips/API/current/VipsForeignSave.html#vips-svgload
    @vips_image ||= Vips::Image.new_from_file(path)
  end

  def to_image_svg_xml(dest, *a, **k, &b)
    if abstract(:optimize)
      SvgOptimizer.optimize_file(path, dest, SvgOptimizer::DEFAULT_PLUGINS)
    else
      copy_file(dest, *a, **k, &b)
    end
  end

  def self.optimize(src, dest)
    # TODO: Make optimizations/plugins configurable
    SvgOptimizer.optimize_file(src, dest, SvgOptimizer::DEFAULT_PLUGINS)
  end

end
