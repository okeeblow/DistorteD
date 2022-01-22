
require 'set'

require 'distorted-floor/checking_you_out'
require 'distorted-floor/modular_technology/vips'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::Image


  # Attributes for our <picture>/<img>.
  # Automatically enabled as attrs for DD Liquid Tag.
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture#Attributes
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img#Attributes
  # https://developer.mozilla.org/en-US/docs/Web/Performance/Lazy_loading
  ATTRIBUTES = Set[:alt, :caption, :href, :loading]

  # Defaults for HTML Element attributes.
  # Not every attr has to be listed here.
  # Many need no default and just won't render.
  ATTRIBUTES_DEFAULT = {
    :loading => :eager,
  }
  ATTRIBUTES_VALUES = {
    :loading => Set[:eager, :lazy],
  }

  include Cooltrainer::DistorteD::Technology::Vips

end  # Image
