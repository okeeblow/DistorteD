require 'set'
require 'distorted/monkey_business/set'

require 'distorted/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT

require 'distorted/modular_technology/gstreamer'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::Video

  LOWER_WORLD = {
    ::CHECKING::YOU::OUT::from_ietf_media_type('video/mp4') => nil,
  }

  include Cooltrainer::DistorteD::Technology::GStreamer

end  # Video
