require 'set'

require 'distorted/checking_you_out'
require 'distorted/injection_of_love'

require 'distorted/modular_technology/gstreamer'


module Cooltrainer
  module DistorteD
    module Video

      LOWER_WORLD = CHECKING::YOU::IN('video/mp4')

      # Attributes for our <video>.
      # Automatically enabled as attrs for DD Liquid Tag.
      # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/video#Attributes
      ATTRIBUTES = Set[:caption]

      # Defaults for HTML Element attributes.
      # Not every attr has to be listed here.
      # Many need no default and just won't render.
      ATTRIBUTES_DEFAULT = {}
      ATTRIBUTES_VALUES = {}

      include Cooltrainer::DistorteD::Technology::GStreamer
      include Cooltrainer::DistorteD::InjectionOfLove

    end  # Video
  end  # DistorteD
end  # Cooltrainer
