require 'set'

require 'distorted/molecule/svg'
require 'distorted-jekyll/liquid_liquid/picture'


module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::SVG

  include Cooltrainer::DistorteD::Molecule::SVG
  include Jekyll::DistorteD::LiquidLiquid::Picture

  define_method(
    CHECKING::YOU::OUT['image/svg+xml'].distorted_template_method,
    Jekyll::DistorteD::LiquidLiquid::Picture::render_picture_source,
  )

end
