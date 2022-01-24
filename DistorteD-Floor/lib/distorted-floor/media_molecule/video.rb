require 'set'
require 'distorted-floor/monkey_business/set'

require 'distorted-floor/checking_you_out'
using ::DistorteD::CHECKING::YOU::OUT

require 'distorted-floor/modular_technology/gstreamer'


module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::Molecule; end
module Cooltrainer::DistorteD::Molecule::Video

  LOWER_WORLD = {
    ::CHECKING::YOU::OUT::from_iana_media_type('video/mp4') => nil,
  }

  include Cooltrainer::DistorteD::Technology::GStreamer

end  # Video
