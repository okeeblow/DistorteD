require 'set'

require 'distorted-jekyll/liquid_liquid/picture'
require 'distorted/media_molecule/image'


module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::Image

  include Cooltrainer::DistorteD::Molecule::Image
  include Jekyll::DistorteD::LiquidLiquid::Picture

end
