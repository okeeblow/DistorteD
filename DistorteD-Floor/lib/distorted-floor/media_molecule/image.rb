
require 'set'

require 'distorted/checking_you_out'
require 'distorted/modular_technology/vips'
require 'distorted/injection_of_love'


module Cooltrainer
  module DistorteD
    module Image


      # Attributes for our <picture>/<img>.
      # Automatically enabled as attrs for DD Liquid Tag.
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture#Attributes
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/img#Attributes
      # https://developer.mozilla.org/en-US/docs/Web/Performance/Lazy_loading
      ATTRS = Set[:alt, :caption, :href, :loading]

      # Defaults for HTML Element attributes.
      # Not every attr has to be listed here.
      # Many need no default and just won't render.
      ATTRS_DEFAULT = {
        :loading => :eager,
      }
      ATTRS_VALUES = {
        :loading => Set[:eager, :lazy],
      }

      include Cooltrainer::DistorteD::Technology::Vips
      include Cooltrainer::DistorteD::InjectionOfLove

    end  # Image
  end  # DistorteD
end  # Cooltrainer
