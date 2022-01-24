require 'set'

require 'distorted-floor/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT
require 'distorted-floor/media_molecule/svg'
require 'distorted-jekyll/liquid_liquid/picture'


module Jekyll; end
module Jekyll::DistorteD; end
module Jekyll::DistorteD::Molecule; end
module Jekyll::DistorteD::Molecule::SVG

  include Cooltrainer::DistorteD::Molecule::SVG
  include Jekyll::DistorteD::LiquidLiquid::Picture

  define_method(
    ::CHECKING::YOU::OUT::from_iana_media_type(-'image/svg+xml').distorted_template_method,
    ::Jekyll::DistorteD::LiquidLiquid::Picture::render_picture_source,
  )

end
