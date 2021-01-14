require 'set'

require 'distorted/media_molecule/text'
require 'distorted-jekyll/liquid_liquid/picture'


module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::Text

  include Cooltrainer::DistorteD::Molecule::Text
  include Jekyll::DistorteD::LiquidLiquid::Picture

  Cooltrainer::DistorteD::IMPLANTATION(:LOWER_WORLD, Cooltrainer::DistorteD::Molecule::Text).each_key { |type|
    define_method(type.distorted_template_method) { |change|
      # Remove the destructured empty Hash once we drop Ruby 2.7
      # so we don't get auto-destructured due to Change#to_hash.
      Cooltrainer::ElementalCreation.new(:anchor_inline, change, **{})
    }
  }

end  # Text
