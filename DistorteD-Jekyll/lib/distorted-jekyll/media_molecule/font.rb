require 'set'

require 'distorted/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT
require 'distorted/media_molecule/font'
require 'distorted-jekyll/liquid_liquid/picture'


module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::Font

  include Cooltrainer::DistorteD::Molecule::Font
  include Jekyll::DistorteD::LiquidLiquid::Picture

  Cooltrainer::DistorteD::IMPLANTATION(:LOWER_WORLD, Cooltrainer::DistorteD::Molecule::Font).each_key { |type|
    define_method(type.distorted_template_method) { |change|
      Cooltrainer::ElementalCreation.new(:anchor_inline, change, **{})
    }
  }

end
